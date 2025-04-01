//
//  DownloadQueue.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation

actor DownloadQueue {
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
    private let continuation: AsyncStream<Event>.Continuation
    
    private let urlSession: URLSession
    private let maxConcurrentDownloads: Int
    private var downloadQueue: [QueueElement] = []
    private var activeDownloads: [URL: FileDownload] = [:]

    init(maxConcurrentDownloads: Int = 6) {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        self.urlSession = URLSession(configuration: config)
        
        self.maxConcurrentDownloads = maxConcurrentDownloads
        (self.events, self.continuation) = AsyncStream.makeStream(of: Event.self)
        
        continuation.onTermination = { [weak self] _ in
            Task { [weak self] in
                await self?.cancelAllDownloads(pausing: false)
            }
        }
    }

    func downloadFiles(from urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { await self.downloadFile(from: url) }
            }
        }
    }

    func downloadFile(from url: URL) async {
        if let index = downloadQueue.firstIndex(where: { $0.url == url }) {
            if case let .paused(data) = downloadQueue[index].state {
                downloadQueue[index].state = .queued(resumeData: data)
            } else {
                return
            }
        } else {
            downloadQueue.append(QueueElement(url: url, state: .queued(resumeData: nil)))
        }
        
        continuation.yield(Event(state: .queued, url: url))
        
        if activeDownloads.count < maxConcurrentDownloads {
            await startDownload(from: url)
        }
    }

    func cancelDownload(url: URL, pausing: Bool = true) async {
        if let download = activeDownloads[url] {
            download.cancel(pausing: pausing)
        } else if !pausing, let index = downloadQueue.firstIndex(where: { $0.url == url }) {
            switch downloadQueue[index].state {
            case let .queued(data):
                await deleteQueuedDownload(index: index, url: url, resumeData: data)
            case let .paused(data):
                await deleteQueuedDownload(index: index, url: url, resumeData: data)
            default:
                break
            }
        }
    }

    func cancelAllDownloads(pausing: Bool = true) async {
        for url in activeDownloads.keys {
            await cancelDownload(url: url, pausing: pausing)
        }
    }
}

// MARK: - Private Helpers
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

    func deleteQueuedDownload(index: Int, url: URL, resumeData: Data?) async {
        downloadQueue.remove(at: index)
        continuation.yield(Event(state: .canceled, url: url))
        
        if let resumeData = resumeData {
            await deleteDownloadTmpFile(resumeData: resumeData)
        }
    }

    func deleteDownloadTmpFile(resumeData: Data) async {
        let download = FileDownload(resumeData: resumeData, urlSession: urlSession)
        download.start()
        download.cancel(pausing: false)
    }

    func processDownloadQueue() async {
        while activeDownloads.count < maxConcurrentDownloads {
            if let element = downloadQueue.first(where: { $0.isQueued }) {
                await startDownload(from: element.url)
            } else {
                break
            }
        }
    }

    func startDownload(from url: URL) async {
        guard let index = downloadQueue.firstIndex(where: { $0.url == url }) else { return }
        let oldElement = downloadQueue[index]
        downloadQueue[index].state = .downloading

        let download = oldElement.resumeData.map {
            FileDownload(resumeData: $0, urlSession: urlSession)
        } ?? FileDownload(url: url, urlSession: urlSession)
        
        activeDownloads[url] = download
        download.start()

        Task {
            for await event in download.events {
                await process(event, for: url)
            }
            await processDownloadQueue()
        }
    }

    func process(_ event: FileDownload.Event, for url: URL) async {
        switch event {
        case .completed, .failed:
            downloadQueue.removeAll { $0.url == url }
            activeDownloads.removeValue(forKey: url)
        case let .canceled(data, pausing):
            if let index = downloadQueue.firstIndex(where: { $0.url == url }) {
                if pausing {
                    downloadQueue[index].state = .paused(resumeData: data)
                } else {
                    downloadQueue.remove(at: index)
                }
            }
            activeDownloads.removeValue(forKey: url)
        default: break
        }
        continuation.yield(Event(state: event.downloadState, url: url))
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
