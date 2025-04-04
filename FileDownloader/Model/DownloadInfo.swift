//
//  DownloadInfo.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation

struct DownloadInfo: Equatable {
    let url: URL
    private(set) var state: DownloadInfo.State = .pending
    private(set) var bytesDownloaded: Int64 = 0
    private(set) var totalBytes: Int64 = 0
}

extension DownloadInfo {
    enum State {
        case pending
        case queued
        case downloading
        case completed
        case failed
        case paused
    }

    init(url: URL, state: DownloadInfo.State) {
        self.url = url
        self.state = state
    }

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesDownloaded) / Double(totalBytes)
    }

    var fileURL: URL {
        URL.documentsDirectory
            .appending(path: "\(id.nonCryptoHash)")
            .appendingPathExtension("m4a")
    }

    mutating func update(state: DownloadInfo.State) {
        self.state = state
    }

    mutating func update(bytesDownloaded: Int64? = nil, totalBytes: Int64? = nil) {
        if let bytesDownloaded {
            self.bytesDownloaded = bytesDownloaded
        }
        if let totalBytes {
            self.totalBytes = totalBytes
        }
    }
}

extension DownloadInfo: Identifiable {
    var id: String { url.absoluteString }
}
