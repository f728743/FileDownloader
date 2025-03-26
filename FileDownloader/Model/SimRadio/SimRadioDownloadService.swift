import Foundation

actor SimRadioDownloadService {
    @MainActor private let mediaState: MediaState
    private let downloadQueue: DownloadQueue
    private var stationDownloads: [SimStation.ID: DownloadableStation] = [:]
    private var groupDownloads: [SimFileGroup.ID: DownloadableFileGroup] = [:]
    private var groupOfURL: [URL: SimFileGroup.ID] = [:]

    private var eventContinuation: AsyncStream<Event>.Continuation?
    private(set) lazy var events: AsyncStream<Event> = AsyncStream { continuation in
        self.eventContinuation = continuation
    }

    enum Event: Equatable {
        case updatedFileGroup(id: SimFileGroup.ID, status: DownloadStatus)
        case updatedStation(id: SimStation.ID, status: DownloadStatus)
    }

    struct DownloadStatus: Equatable, DownloadProgressProtocol {
        let state: DownloadState
        let totalBytes: Int64
        let bytesDownloaded: Int64
    }

    enum DownloadState: Equatable {
        case queued
        case downloading
        case completed
        case paused
        case failed([URL])
    }

    struct DownloadableStation: Equatable {
        var status: DownloadStatus
        let fileGroupIDs: [SimFileGroup.ID]
    }

    struct DownloadableFileGroup: Equatable {
        let id: SimFileGroup.ID
        var files: [DownloadInfo]
    }

    init(mediaState: MediaState, maxConcurrentDownloads: Int = 6) {
        self.mediaState = mediaState
        downloadQueue = DownloadQueue(maxConcurrentDownloads: maxConcurrentDownloads)

        Task { [weak self] in
            guard let self else { return }
            let stream = self.downloadQueue.events
            for await event in stream {
                await self.processDownloaderEvent(event)
            }
            await self.finishEventStream()
        }
    }

    deinit {
        eventContinuation?.finish()
    }

    nonisolated func downloadMedia(withID id: MediaID) {
        Task {
            await doDownloadMedia(withID: id)
        }
    }
}

private extension SimRadioDownloadService {
    func finishEventStream() {
        eventContinuation?.finish()
        eventContinuation = nil
    }

    func doDownloadMedia(withID id: MediaID) async {
        guard case let .simRadio(stationID) = id else { return }

        // Access mediaState on the MainActor
        let stations = await mediaState.simRadio.stations
        guard let station = stations[stationID] else {
            print("SimRadioDownloadService Error: Station \(stationID) not found in mediaState")
            return
        }

        guard !stationDownloads.keys.contains(stationID) else {
            print("SimRadioDownloadService: Station \(stationID) already tracked for download.")
            // Optionally: Re-evaluate state or publish current status?
            return
        }

        print("SimRadioDownloadService: Starting download for station \(stationID)")
        await download(station: station)
    }

    func download(station: SimStation) async {
        stationDownloads[station.id] = DownloadableStation(
            status: .init(state: .queued, totalBytes: 0, bytesDownloaded: 0),
            fileGroupIDs: station.fileGroups
        )

        var groupURLs: [SimFileGroup.ID: [URL]] = [:]
        let allFileGroups = await mediaState.simRadio.fileGroups // Access MainActor state
        for groupID in station.fileGroups {
            guard groupDownloads[groupID] == nil else {
                continue
            }

            guard let urls = allFileGroups[groupID]?.files.compactMap({ $0.url }) else {
                continue
            }

            let urlGroups = urls.map { ($0, groupID) }
            let groupOfURLUpdate = Dictionary(uniqueKeysWithValues: urlGroups)
            groupOfURL = groupOfURL.merging(groupOfURLUpdate) { _, new in new }

            let files = urls.map { DownloadInfo(url: $0) } // Initial state is .queued
            let downloadableGroup = DownloadableFileGroup(id: groupID, files: files)
            groupDownloads[groupID] = downloadableGroup
            groupURLs[groupID] = urls
        }

        for (groupID, urls) in groupURLs {
            print("SimRadioDownloadService: Queuing group \(groupID) " +
                "with \(urls.count) files for station \(station.id.value)")
            Task {
                await updateFileSizes(for: urls, groupID: groupID) // Pass groupID here too
            }
            await downloadQueue.downloadFiles(from: urls)
        }

        // Update the station's entry with all its group IDs
        if var stationDownload = stationDownloads[station.id] {
            // Calculate initial state/progress after adding groups
            let calculatedStatus = await calculateStationStatus(stationID: station.id)
            stationDownload.status = calculatedStatus
            stationDownloads[station.id] = stationDownload
            // Yield initial station status event
            eventContinuation?.yield(.updatedStation(id: station.id, status: calculatedStatus))
        }
    }

    func processDownloaderEvent(_ event: DownloadQueue.Event) async {
        guard let groupID = groupOfURL[event.url],
              let fileIndex = groupDownloads[groupID]?.files.firstIndex(where: { $0.url == event.url })
        else {
            print("SimRadioDownloadService process: missing groupID or fileIndex for event: \(event)")
            return
        }

        guard var groupInfo = groupDownloads[groupID] else {
            print("SimRadioDownloadService process: Group \(groupID) not found for event: \(event)")
            return
        }

        let (fileInfo, stateChanged) = groupInfo.files[fileIndex].updated(queueState: event.state)

        // Update the file info in the group
        groupInfo.files[fileIndex] = fileInfo
        // Update the group info in the main dictionary
        groupDownloads[groupID] = groupInfo

        // TODO: removeValue(forKey: url) when url finished or canceled
        // --- Event Publishing Logic ---
        // Only publish if state potentially changed or progress occurred
        if stateChanged || event.isProgress {
            // 1. Calculate and yield group status
            let groupStatus = groupState(groupID) // Use existing helper
            eventContinuation?.yield(.updatedFileGroup(id: groupID, status: groupStatus))

            // 2. Find the station associated with this group
            let groupStations = findStationIDs(for: groupID)
            for stationID in groupStations {
                // 3. Calculate and yield station status
                let stationStatus = await calculateStationStatus(stationID: stationID)

                // Update internal state as well
                stationDownloads[stationID]?.status = stationStatus

                eventContinuation?.yield(.updatedStation(id: stationID, status: stationStatus))
            }
            if groupStations.isEmpty {
                print("SimRadioDownloadService process: Could not find station for groupID \(groupID)")
            }
        }
        // --- End Event Publishing Logic ---

        // Optional: Keep printProgress for debugging? Remove if events are handled externally.
        printProgress()
    }

    func findStationIDs(for groupID: SimFileGroup.ID) -> [SimStation.ID] {
        stationDownloads.compactMap { id, download in
            download.fileGroupIDs.contains(groupID) ? id : nil
        }
    }

    /// Calculates the aggregated download status for a station based on its groups.
    func calculateStationStatus(stationID: SimStation.ID) async -> DownloadStatus {
        guard let stationDownloadInfo = stationDownloads[stationID] else {
            // Should not happen if called correctly
            print("SimRadioDownloadService Error: Station \(stationID) not found during status calculation.")
            return DownloadStatus(state: .queued, totalBytes: 0, bytesDownloaded: 0)
        }

        var groupStatuses: [DownloadStatus] = []
        for groupID in stationDownloadInfo.fileGroupIDs {
            // Get the status for each group associated with the station
            let groupStatus = groupState(groupID) // Use existing helper
            groupStatuses.append(groupStatus)
        }

        // Aggregate status from the collected group statuses
        let overallState = groupStatuses.downloadState // Use existing extension
        let totalBytes = groupStatuses.reduce(0) { $0 + ($1.totalBytes) } // Ensure positive
        let bytesDownloaded = groupStatuses.reduce(0) { $0 + ($1.bytesDownloaded) }

        // Return the newly calculated status for the station
        return DownloadStatus(
            state: overallState, // Map SimDownloadStateInternal back to DownloadState
            totalBytes: totalBytes,
            bytesDownloaded: bytesDownloaded,
        )
    }

    /// Calculates the aggregated download status for a specific file group.
    func groupState(_ groupID: SimFileGroup.ID) -> DownloadStatus {
        guard let group = groupDownloads[groupID] else {
            print("SimRadioDownloadService Warning: groupState called for unknown groupID \(groupID)")
            return DownloadStatus(
                state: .queued,
                totalBytes: 0,
                bytesDownloaded: 0,
            )
        }

        let overallState = group.files.downloadState // Use extension on collection of DownloadInfo
        let totalBytes = group.files.reduce(0) { $0 + ($1.totalBytes) }
        let bytesDownloaded = group.files.reduce(0) { $0 + ($1.bytesDownloaded) }

        return DownloadStatus(
            state: overallState,
            totalBytes: totalBytes,
            bytesDownloaded: bytesDownloaded,
        )
    }

    /// Fetches and updates the total size for each file URL using HEAD requests.
    func updateFileSizes(for urls: [URL], groupID: SimFileGroup.ID) async {
        print("SimRadioDownloadService: Updating file sizes for group \(groupID)")
        await withTaskGroup(of: (URL, Int64?).self) { group in
            for url in urls {
                group.addTask {
                    var request = URLRequest(url: url)
                    request.httpMethod = "HEAD"
                    do {
                        let (_, response) = try await URLSession.shared.data(for: request)
                        // Check for Content-Length header
                        let contentLength = response.expectedContentLength // This is Int64
                        return (url, contentLength > 0 ? contentLength : nil) // Return nil if size is unknown/invalid
                    } catch {
                        print("SimRadioDownloadService: Failed to fetch size for \(url.lastPathComponent): \(error)")
                        return (url, nil) // Indicate failure to get size
                    }
                }
            }

            // Collect results as they complete
            for await(url, size) in group {
                if let size = size {
                    update(fileURL: url, groupID: groupID, size: size)
                }
            }
        }
        print("SimRadioDownloadService: Finished updating file sizes for group \(groupID)")

        // After sizes are updated, recalculate and yield status updates
        // This ensures progress calculation is accurate sooner.
        let groupStatus = groupState(groupID)
        eventContinuation?.yield(.updatedFileGroup(id: groupID, status: groupStatus))
        let groupStations = findStationIDs(for: groupID)
        for stationID in groupStations {
            let stationStatus = await calculateStationStatus(stationID: stationID)
            stationDownloads[stationID]?.status = stationStatus // Update internal state
            eventContinuation?.yield(.updatedStation(id: stationID, status: stationStatus))
        }
    }

    /// Updates the total size for a specific file within a group.
    private func update(fileURL: URL, groupID: SimFileGroup.ID, size: Int64) {
        guard var groupInfo = groupDownloads[groupID],
              let fileIndex = groupInfo.files.firstIndex(where: { $0.url == fileURL })
        else {
            print("SimRadioDownloadService Error: File \(fileURL.lastPathComponent) " +
                "or group \(groupID) not found for size update.")
            return
        }

        groupInfo.files[fileIndex].update(totalBytes: size)
        groupDownloads[groupID] = groupInfo
        // No need to yield here, updateFileSizes handles yielding after all sizes are fetched.
    }

    func printProgress(verbose: Bool = false) {
        // TODO: check overall.downloadState & station.status.state
        let overall = Array(stationDownloads.values)
        print("--- Download Progress (\(Date().ISO8601Format())) ---")
        print("Overall: \(overall.downloadState) - \(overall.progressString)")
        for (stationID, station) in stationDownloads {
            print("  Station \(stationID.value): \(station.status.state) - \(station.progressString)")
            for groupID in station.fileGroupIDs {
                let group = groupState(groupID)
                print("    Group \(groupID.value): \(group.state) - \(group.progressString)")
                // Optional: Print individual file status within group for detailed debug
                if verbose, let group = groupDownloads[groupID] {
                    for file in group.files {
                        let fileName = file.url.lastPathComponent
                        print("      File \(fileName): \(file.state) - \(file.progressString)")
                    }
                }
            }
        }
        print("---------------------------------------")
    }
}

extension DownloadInfo {
    // TODO: check logic
    func updated(queueState: DownloadQueue.DownloadState) -> (info: DownloadInfo, stateChanged: Bool) {
        var result = self
        var stateChanged = false
        // Update file state based on the event
        let previousState = state
        switch queueState {
        case let .progress(bytesDownloaded, totalBytes):
            if state != .downloading { // Only set downloading on first progress?
                // fileInfo.state = .downloading // Let group state calc handle this?
                // stateChanged = previousState != fileInfo.state
            }
            // Always update bytes, state remains downloading implicitly
            // unless changed by other events. If it was paused, progress indicates resume.
            if state == .paused || state == .queued {
                result.update(state: .downloading)
                stateChanged = true
            }
            result.update(bytesDownloaded: bytesDownloaded, totalBytes: totalBytes)

        case .completed:
            result.update(state: .completed)
            // Ensure progress is 100% if totalBytes is known
            if totalBytes > 0 {
                result.update(bytesDownloaded: totalBytes)
            } else {
                // If total size wasn't fetched, maybe try again or log warning?
                print("SimRadioDownloadService Warning: File \(url.lastPathComponent) " +
                    "completed with unknown total size.")
            }
            stateChanged = previousState != state

        case let .failed(error):
            // Store error description or keep simple .failed state?
            // Let's keep it simple for now, aggregation collects URLs.
            result.update(state: .failed) // Indicate failure
            stateChanged = previousState != state
            print("SimRadioDownloadService: Download failed for \(url.lastPathComponent) " +
                "in group \("groupID"): \(error.localizedDescription)")

        case .paused:
            if state == .downloading { // Only transition from downloading to paused
                result.update(state: .paused)
                stateChanged = true
            }

        case .queued:
            // Usually means download hasn't started or was reset.
            if state != .queued { // Only update if not already queued
                result.update(state: .queued)
                stateChanged = true
            }

        case .canceled:
            // Treat cancel as reverting to queued or a distinct state?
            // Reverting to queued might be simplest for now.
            if state != .queued {
                result.update(state: .queued)
                result.update(bytesDownloaded: 0) // Reset progress on cancel
                stateChanged = true
            }
        }
        return (info: result, stateChanged: stateChanged)
    }
}

extension SimRadioDownloadService.DownloadableStation: DownloadProgressProtocol {
    var totalBytes: Int64 { status.totalBytes }
    var bytesDownloaded: Int64 { status.bytesDownloaded }
}

extension DownloadQueue.Event {
    var isProgress: Bool {
        if case .progress = state { return true }
        return false
    }
}

extension Int64 {
    private nonisolated(unsafe) static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useMB
        formatter.countStyle = .file
        return formatter
    }()

    var bytesToMB: String {
        return Self.formatter.string(fromByteCount: Swift.max(0, self))
    }
}

protocol DownloadProgressProtocol {
    var totalBytes: Int64 { get }
    var bytesDownloaded: Int64 { get }
}

extension DownloadProgressProtocol {
    var progress: Double {
        guard totalBytes != 0 else { return 0.0 }
        return (Double(bytesDownloaded) / Double(totalBytes)).clamped(to: 0.0 ... 1.0)
    }

    var percent: Double { progress * 100 }
    var percentString: String { String(format: "%.1f%%", percent) }
    var progressString: String { "\(percentString) (\(bytesDownloaded.bytesToMB) / \(totalBytes.bytesToMB))" }
}

extension Array: DownloadProgressProtocol where Element: DownloadProgressProtocol {
    var totalBytes: Int64 { reduce(0) { $0 + $1.totalBytes } }
    var bytesDownloaded: Int64 { reduce(0) { $0 + $1.bytesDownloaded } }
}

// Internal enum to simplify state aggregation
enum SimDownloadStateInternal: Equatable {
    case downloading
    case completed
    case paused
    case failed
    case queued
}

// Protocol combining state and progress for aggregation
protocol SimDownloadStateInternalProtocol {
    var internalState: SimDownloadStateInternal { get }
    var failedURLs: [URL] { get }
}

extension SimRadioDownloadService.DownloadStatus: SimDownloadStateInternalProtocol {
    var failedURLs: [URL] {
        if case let .failed(urls) = state {
            return urls
        } else {
            return []
        }
    }

    var internalState: SimDownloadStateInternal {
        switch state {
        case .downloading: return .downloading
        case .completed: return .completed
        case .paused: return .paused
        case .failed: return .failed
        case .queued: return .queued
        }
    }
}

// Make DownloadStatus conform (used for aggregating station status from group statuses)
extension SimRadioDownloadService.DownloadableStation: SimDownloadStateInternalProtocol {
    var failedURLs: [URL] {
        status.failedURLs
    }

    var internalState: SimDownloadStateInternal {
        switch status.state {
        case .downloading: return .downloading
        case .completed: return .completed
        case .paused: return .paused
        case .failed: return .failed
        case .queued: return .queued
        }
    }
}

extension DownloadInfo: SimDownloadStateInternalProtocol {
    var failedURLs: [URL] {
        if case .failed = state {
            return [url]
        } else {
            return []
        }
    }

    var internalState: SimDownloadStateInternal {
        switch state {
        case .downloading: return .downloading
        case .completed: return .completed
        case .paused: return .paused
        case .failed: return .failed
        case .pending: return .queued
        case .queued: return .queued
        }
    }
}

// Aggregation logic for collections
extension Collection where Element: SimDownloadStateInternalProtocol {
    var downloadState: SimRadioDownloadService.DownloadState {
        if contains(where: { $0.internalState == .downloading }) {
            return .downloading
        }

        let finalStates: [SimDownloadStateInternal] = [.completed, .paused, .failed]
        if let state = finalStates.first(where: { state in
            allSatisfy { $0.internalState == state }
        }) {
            switch state {
            case .completed: return .completed
            case .paused: return .paused
            case .failed: return .failed(flatMap { $0.failedURLs })
            default: fatalError()
            }
        }
        return .queued
    }
}

extension DownloadInfo: DownloadProgressProtocol {}
