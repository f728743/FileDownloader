//
//  DownloadQueue.swift
//
//
//  Created by Alexey Vorobyov
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

    private let urlSession: URLSession
    private let maxConcurrentDownloads: Int
    private let continuation: AsyncStream<Event>.Continuation
    private var downloadQueue: [QueueElement] = []
    private var downloads: [URL: FileDownload] = [:]

    init(maxConcurrentDownloads: Int = 6) {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        urlSession = URLSession(configuration: config)

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

    func downloadFile(from url: URL) {
        if let index = downloadQueue.firstIndex(where: { $0.url == url }) {
            if case let .paused(data) = downloadQueue[index].state {
                downloadQueue[index].state = .queued(resumeData: data)
            } else {
                return
            }
        } else {
            downloadQueue.append(QueueElement(url: url, state: .queued(resumeData: nil)))
        }
        continuation.yield(.init(state: .queued, url: url))
        if activeDownloadsCount < maxConcurrentDownloads {
            startDownload(from: url)
        }
    }

    func cancelDownload(url: URL, pausing: Bool = true) {
        if let download = downloads[url] {
            download.cancel(pausing: pausing)
        } else if !pausing, let index = downloadQueue.firstIndex(where: { $0.url == url }) {
            switch downloadQueue[index].state {
            case let .queued(data):
                deleteQueuedDownload(index: index, url: url, resumeData: data)
            case let .paused(data):
                deleteQueuedDownload(index: index, url: url, resumeData: data)
            default:
                break
            }
        }
    }

    func cancelAllDownloads(pausing: Bool = true) {
        downloads.forEach { cancelDownload(url: $0.key, pausing: pausing) }
    }
}

private extension DownloadQueue {
    enum ElementState {
        case queued(resumeData: Data?)
        case downloading
        case paused(resumeData: Data?)
    }

    struct QueueElement {
        let url: URL
        var state: ElementState
    }

    var activeDownloadsCount: Int {
        downloadQueue.count { $0.isDownloading }
    }

    func deleteQueuedDownload(index: Int, url: URL, resumeData: Data?) {
        downloadQueue.remove(at: index)
        continuation.yield(.init(state: .canceled, url: url))
        if let resumeData = resumeData {
            deleteDownloadTmpFile(resumeData: resumeData)
        }
    }

    func deleteDownloadTmpFile(resumeData: Data) {
        Task {
            let download = FileDownload(resumeData: resumeData, urlSession: urlSession)
            download.start()
            download.cancel(pausing: false)
        }
    }

    func processDownloadQueue() {
        while activeDownloadsCount < maxConcurrentDownloads {
            if let element = downloadQueue.first(where: { $0.isQueued }) {
                startDownload(from: element.url)
            } else {
                break
            }
        }
    }

    func startDownload(from url: URL) {
        guard let index = downloadQueue.firstIndex(where: { $0.url == url }) else { return }
        let oldElement = downloadQueue[index]
        downloadQueue[index].state = .downloading

        Task {
            let download = oldElement.resumeData.map {
                FileDownload(resumeData: $0, urlSession: urlSession)
            } ?? FileDownload(url: url, urlSession: urlSession)
            downloads[url] = download
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
        case .completed, .failed:
            downloadQueue.removeAll { $0.url == url }
            downloads.removeValue(forKey: url)
        case let .canceled(data, pausing):
            if let index = downloadQueue.firstIndex(where: { $0.url == url }) {
                if pausing {
                    downloadQueue[index].state = .paused(resumeData: data)
                } else {
                    downloadQueue.remove(at: index)
                }
            }
            downloads.removeValue(forKey: url)
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
        case let .canceled(_, pausing):
            pausing ? .paused : .canceled
        }
    }
}

extension DownloadQueue.QueueElement {
    var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }

    var isQueued: Bool {
        if case .queued = state { return true }
        return false
    }

    var resumeData: Data? {
        if case let .queued(data) = state { return data }
        return nil
    }
}
