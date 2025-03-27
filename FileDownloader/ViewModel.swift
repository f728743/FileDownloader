//
//  ViewModel.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation

@MainActor
class ViewModel: ObservableObject {
    @Published var files: [DownloadInfo] = Config.files.map { DownloadInfo(url: $0, state: .pending) }
    static let list = Const.largeFiles
    private var downloader = DownloadQueue(maxConcurrentDownloads: 2)
    var mediaList: MediaList {
        mediaState.mediaList.first ?? .empty
    }

    @Published var mediaState: MediaState = .empty

    init() {
        Task {
            for await event in downloader.events {
                process(event)
            }
        }
    }

    func viewTask() async {
        let baseUrlStr = "https://raw.githubusercontent.com/tmp-acc/GTA-V-Radio-Stations/master"
        let urlStr = "\(baseUrlStr)/sim_radio_stations.json"
        guard let url = URL(string: urlStr) else { return }
        if let radio = try? await loadSimRadioSeries(url: url) {
            mediaState = .init(simRadio: .init(dto: radio, origin: url))
            if false {
                let urls = mediaState.simRadio.fileGroups.values.flatMap {
                    $0.files.flatMap { $0.allUrls }
                }
                Task {
                    let size = try await calculateTotalSize(for: urls)
                    let total = size.values.reduce(0, +)
                    print(total)
                }
            }
        }
    }

    func loadSimRadioSeries(url: URL) async throws -> SimRadioDTO.Series {
        let (data, _) = try await URLSession.shared.data(from: url)
        let series = try JSONDecoder().decode(SimRadioDTO.Series.self, from: data)
        return series
    }

    func downloadMedia(withID id: MediaID) {
        guard case let .simRadio(id) = id else { return }
        guard let station = mediaState.simRadio.stations[id] else { return }
        let urls = station.fileGroups
            .flatMap { mediaState.simRadio.fileGroups[$0]?.files ?? [] }
            .flatMap { $0.allUrls }

        Task {
            let size = try await calculateTotalSize(for: urls)
            let total = size.values.reduce(0, +)
            print("download \"\(station.info.title)\", \(converByteToGB(total))")
        }
    }

    func toggleDownload(url: URL) {
        if let file = files.first(where: { $0.url == url }), file.state == .downloading {
            downloader.cancelDownload(url: url, pausing: true)
        } else {
            downloader.downloadFile(from: url)
        }
    }

    func cancelDownload(url: URL) {
        downloader.cancelDownload(url: url, pausing: false)
    }

    func downloadAll() {
        downloader.downloadFiles(from: Config.files)
    }

    enum Config {
        static let files = Const.largeFiles
    }
}

func converByteToGB(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .binary
    return formatter.string(fromByteCount: Int64(bytes))
}

extension SimFile {
    var allUrls: [URL] {
        [url] + attaches.map { $0.url }
    }
}

private extension ViewModel {
    func process(_ event: DownloadQueue.Event) {
        guard let index = files.firstIndex(where: { $0.url == event.url }) else { return }
        files[index].update(state: event.state.downloadInfoState)

        switch event.state {
        case .queued:
            files[index].update(currentBytes: 0)
        case let .completed(localURL):
            print("Downloaded", localURL.path)
        case let .progress(currentBytes, totalBytes):
            files[index].update(currentBytes: currentBytes, totalBytes: totalBytes)
        case let .failed(error):
            print("Error", error.localizedDescription)
        default: break
        }
    }
}

extension DownloadQueue.DownloadState {
    var downloadInfoState: DownloadInfo.State {
        switch self {
        case .queued: .queued
        case .progress: .downloading
        case .completed: .completed
        case .canceled: .pending
        case .paused: .paused
        case .failed: .failed
        }
    }
}
