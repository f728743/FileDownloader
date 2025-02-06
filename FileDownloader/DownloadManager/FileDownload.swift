//
//  FileDownload.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation

final class FileDownload: NSObject {
    let events: AsyncStream<Event>
    private let continuation: AsyncStream<Event>.Continuation
    private let urlSessionTask: URLSessionDownloadTask

    enum Event {
        case progress(currentBytes: Int64, totalBytes: Int64)
        case completed(url: URL)
        case canceled(data: Data?, pausing: Bool)
        case failed(error: Error)
    }

    convenience init(url: URL, urlSession: URLSession) {
        self.init(urlSessionTask: urlSession.downloadTask(with: url))
    }

    convenience init(resumeData data: Data, urlSession: URLSession) {
        self.init(urlSessionTask: urlSession.downloadTask(withResumeData: data))
    }

    private init(urlSessionTask: URLSessionDownloadTask) {
        self.urlSessionTask = urlSessionTask
        (events, continuation) = AsyncStream.makeStream(of: Event.self)
        super.init()
        continuation.onTermination = { @Sendable [weak self] _ in
            self?.cancel(pausing: false)
        }
    }

    func start() {
        urlSessionTask.delegate = self
        urlSessionTask.resume()
    }

    func cancel(pausing: Bool) {
        if pausing {
            urlSessionTask.cancel { data in
                self.continuation.yield(
                    .canceled(
                        data: pausing ? data : nil,
                        pausing: true
                    )
                )
                self.continuation.finish()
            }
        } else {
            urlSessionTask.cancel()
            continuation.yield(.canceled(data: nil, pausing: false))
            continuation.finish()
        }
    }
}

extension FileDownload: URLSessionDownloadDelegate {
    func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let response = (downloadTask.response as? HTTPURLResponse)
        let statusCode = response?.statusCode ?? 200
        guard (200 ... 399).contains(where: { $0 == statusCode }) else {
            let error: NetworkError = .httpError(
                statusCode: statusCode,
                description: response?.description
            )
            continuation.yield(.failed(error: error))
            continuation.finish()
            return
        }

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
