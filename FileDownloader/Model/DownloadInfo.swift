//
//  DownloadInfo.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation

struct DownloadInfo {
    let url: URL
    private(set) var state: State
    private(set) var currentBytes: Int64 = 0
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

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(currentBytes) / Double(totalBytes)
    }

    var fileURL: URL {
        URL.documentsDirectory
            .appending(path: "\(id.nonCryptoHash)")
            .appendingPathExtension("m4a")
    }

    mutating func update(state: State) {
        self.state = state
    }

    mutating func update(currentBytes: Int64? = nil, totalBytes: Int64? = nil) {
        if let currentBytes {
            self.currentBytes = currentBytes
        }
        if let totalBytes {
            self.totalBytes = totalBytes
        }
    }
}

extension DownloadInfo: Identifiable {
    var id: String { url.absoluteString }
}
