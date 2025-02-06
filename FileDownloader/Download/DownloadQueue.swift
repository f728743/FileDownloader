//
//  DownloadQueue.swift
//  FileDownloader
//
//  Created by Alexey Vorobyov on 12.02.2025.
//

import Foundation

@MainActor
class DownloadQueue {
    struct Event {
        let event: FileDownload.Event
        let url: URL
    }

    let events: AsyncStream<Event>

    private let maxConcurrentDownloads: Int
    private let continuation: AsyncStream<Event>.Continuation
    private let urlSession: URLSession
    private var downloads: [FileDownloadStatus] = []
    private var downloadTasks: [URL: Task<Void, Never>] = [:]
    private var downloadQueue: [URL] = []

    init(maxConcurrentDownloads: Int = 3) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        urlSession = URLSession(configuration: config)

        (events, continuation) = AsyncStream.makeStream(of: Event.self)
        continuation.onTermination = { @Sendable [weak self] _ in
            Task { @MainActor in
                self?.cancelAllDownloads()
            }
        }
    }

    func startDownloads(urls: [URL]) {
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

        //        if let index = downloads.firstIndex(where: { $0.url == url }) {
        //            downloads[index].status = .canceled
        //        }
    }

    func cancelAllDownloads() {
        downloadTasks.forEach { $0.value.cancel() }
        downloadTasks.removeAll()

        //        for index in downloads.indices where downloads[index].status == .downloading {
        //            downloads[index].status = .canceled
        //        }
    }

    func downloadFile(from url: URL) {
        let downloadInfo = FileDownloadStatus(
            url: url,
            status: .queued
        )

        downloads.append(downloadInfo)

        if activeDownloadsCount < maxConcurrentDownloads {
            startDownload(for: url)
        } else {
            downloadQueue.append(url)
        }
    }
}

private extension DownloadQueue {
    var activeDownloadsCount: Int {
        downloads.count { $0.isDownloading }
    }

    func processDownloadQueue() {
        while activeDownloadsCount < maxConcurrentDownloads, !downloadQueue.isEmpty {
            if let downloadURL = downloadQueue.first {
                downloadQueue.removeFirst()
                if let download = downloads.first(where: { $0.url == downloadURL }) {
                    startDownload(for: download.url)
                }
            }
        }
    }

    func startDownload(for url: URL) {
        update(url: url, status: .downloading)
        let task = Task {
            do {
                let download = FileDownload(url: url)
                download.start()

                for await event in download.events {
                    process(event, for: url)
                }
                await MainActor.run {
                    processDownloadQueue()
                }
            }
        }
        downloadTasks[url] = task
    }

    func update(url: URL, status: FileDownloadStatus.Status) {
        guard let index = indexOfDownload(with: url) else { return }
        downloads[index].status = status
    }

    func indexOfDownload(with url: URL) -> Int? {
        downloads.firstIndex(where: { $0.url == url })
    }

    func process(_ event: FileDownload.Event, for url: URL) {
        switch event {
        case let .canceled(data):
            update(url: url, status: .canceled(data: data))
        case .completed:
            downloads.removeAll { $0.url == url }
        default: break
        }
        continuation.yield(.init(event: event, url: url))
    }
}

private struct FileDownloadStatus {
    enum Status {
        case queued
        case downloading
        case failed
        case canceled(data: Data?)
    }

    let url: URL
    var status: Status
}

extension FileDownloadStatus {
    var isDownloading: Bool {
        if case .downloading = status { return true }
        return false
    }
}
