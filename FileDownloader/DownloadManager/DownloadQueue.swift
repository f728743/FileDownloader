//
//  DownloadQueue.swift
//  FileDownloader
//
//  Created by Alexey Vorobyov on 12.02.2025.
//

import Foundation

@MainActor
class DownloadQueue {
    enum DownloadState {
        case queued
        case progress(currentBytes: Int64, totalBytes: Int64)
        case completed(url: URL)
        case canceled
        case paused
        case failed(error: Error)
    }

    struct Event {
        let state: DownloadState
        let url: URL
    }

    let events: AsyncStream<Event>

    private let maxConcurrentDownloads: Int
    private let continuation: AsyncStream<Event>.Continuation
    private var downloadQueue: [QueueElement] = []
    private var downloadTasks: [URL: FileDownload] = [:]

    init(maxConcurrentDownloads: Int = 3) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
        (events, continuation) = AsyncStream.makeStream(of: Event.self)
        continuation.onTermination = { @Sendable [weak self] _ in
            Task { @MainActor in
                self?.cancelAllDownloads()
            }
        }
    }

    func downloadFiles(from urls: [URL]) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        await self.downloadFile(from: url)
                    }
                }
            }
        }
    }

    func cancelDownload(url: URL) {
        downloadTasks[url]?.cancel()
        downloadTasks.removeValue(forKey: url)
    }

    func cancelAllDownloads() {
        downloadTasks.forEach { $0.value.cancel() }
        downloadTasks.removeAll()
    }

    func downloadFile(from url: URL) {
        guard !downloadQueue.contains(where: { $0.url == url }) else { return }
        downloadQueue.append(QueueElement(url: url, state: .enqueued))
        continuation.yield(.init(state: .queued, url: url))
        if activeDownloadsCount < maxConcurrentDownloads {
            startDownload(from: url)
        }
    }
}

private extension DownloadQueue {
    enum ElementState {
        case enqueued
        case downloading
        case paused(resumeData: Data)
    }

    struct QueueElement {
        let url: URL
        var state: ElementState
    }

    var activeDownloadsCount: Int {
        downloadQueue.count { $0.isDownloading }
    }

    func processDownloadQueue() {
        while activeDownloadsCount < maxConcurrentDownloads {
            if let element = downloadQueue.first(where: { $0.isDownloading == false }) {
                startDownload(from: element.url)
            } else {
                break
            }
        }
    }

    func startDownload(from url: URL) {
        guard let index = downloadQueue.firstIndex(where: { $0.url == url }) else { return }
        downloadQueue[index].state = .downloading

        Task {
            let download = FileDownload(url: url)
            downloadTasks[url] = download
            download.start()

            for await event in download.events {
                process(event, for: url)
            }
            await MainActor.run {
                processDownloadQueue()
            }
        }
    }

    func process(_ event: FileDownload.Event, for url: URL) {
        switch event {
        case .completed, .canceled, .failed:
            downloadQueue.removeAll { $0.url == url }
        default: break
        }
        continuation.yield(.init(state: event.downloadState, url: url))
    }
}

extension FileDownload.Event {
    var downloadState: DownloadQueue.DownloadState {
        switch self {
        case let .progress(currentBytes, totalBytes):
            .progress(currentBytes: currentBytes, totalBytes: totalBytes)
        case let .completed(url):
            .completed(url: url)
        case let .failed(error):
            .failed(error: error)
        case .canceled:
            .paused
        }
    }
}

extension DownloadQueue.QueueElement {
    var isDownloading: Bool {
        if case .downloading = state {
            return true
        }
        return false
    }
}
