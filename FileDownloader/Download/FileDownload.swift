//
//  FileDownload.swift
//
//
//

import Foundation

final class FileDownload: NSObject {
    let events: AsyncStream<Event>
    private let continuation: AsyncStream<Event>.Continuation
    private let urlSessionTask: URLSessionDownloadTask

    enum Event {
        case progress(currentBytes: Int64, totalBytes: Int64)
        case completed(url: URL)
        case canceled(data: Data?)
    }

    convenience init(url: URL) {
        self.init(urlSessionTask: URLSession.shared.downloadTask(with: url))
    }

    convenience init(resumeData data: Data) {
        self.init(urlSessionTask: URLSession.shared.downloadTask(withResumeData: data))
    }

    private init(urlSessionTask: URLSessionDownloadTask) {
        self.urlSessionTask = urlSessionTask
        (events, continuation) = AsyncStream.makeStream(of: Event.self)
        super.init()
        continuation.onTermination = { @Sendable [weak self] _ in
            self?.cancel()
        }
    }

    func start() {
        urlSessionTask.delegate = self
        urlSessionTask.resume()
    }

    func cancel() {
        urlSessionTask.cancel { data in
            self.continuation.yield(.canceled(data: data))
            self.continuation.finish()
        }
    }
}

extension FileDownload: URLSessionDownloadDelegate {
    func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        continuation.yield(.completed(url: location))
        continuation.finish()
    }

    func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        continuation.yield(
            .progress(
                currentBytes: totalBytesWritten,
                totalBytes: totalBytesExpectedToWrite
            )
        )
    }
}
