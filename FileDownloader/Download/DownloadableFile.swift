//
//  DownloadableFile.swift
//
//
//

import Foundation

struct DownloadableFile: Identifiable {
    var id: UInt64 { "\(url)".nonCryptoHash }
    let url: URL
    var state: State = .idle
    private(set) var currentBytes: Int64 = 0
    private(set) var totalBytes: Int64 = 0

    enum State: Equatable {
        case idle
        case dowloading
        case completed
        case canceled(resumeData: Data)
    }

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(currentBytes) / Double(totalBytes)
    }

    var isDownloadCompleted: Bool {
        currentBytes == totalBytes && totalBytes > 0
    }

    mutating func update(currentBytes: Int64, totalBytes: Int64) {
        self.currentBytes = currentBytes
        self.totalBytes = totalBytes
    }
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

extension DownloadableFile {
    var fileURL: URL {
        URL.documentsDirectory
            .appending(path: "\(id)")
            .appendingPathExtension("mp3")
    }
}
