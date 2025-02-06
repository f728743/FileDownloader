//
//  DownloadInfo.swift
//
//
//

import Foundation

struct DownloadInfo {
    let url: URL
    private(set) var status: Status
    private(set) var currentBytes: Int64 = 0
    private(set) var totalBytes: Int64 = 0
}

extension DownloadInfo {
    enum Status {
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
            .appendingPathExtension("mp3")
    }

    mutating func update(status: Status) {
        self.status = status
    }

    mutating func update(currentBytes: Int64, totalBytes: Int64) {
        self.currentBytes = currentBytes
        self.totalBytes = totalBytes
    }
}

extension DownloadInfo: Identifiable {
    var id: String { url.absoluteString }
}

extension String {
    var nonCryptoHash: UInt64 {
        var result = UInt64(5381)
        let buf = [UInt8](utf8)
        for byte in buf {
            result = 127 * (result & 0x00FF_FFFF_FFFF_FFFF) + UInt64(byte)
        }
        return result
    }
}
