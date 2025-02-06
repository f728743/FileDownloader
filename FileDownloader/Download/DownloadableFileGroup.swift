//
//  DownloadableFileGroup.swift
//
//
//

import Foundation

struct DownloadableFileGroup {
    let id: UInt64
    var files: [DownloadableFile]

    subscript(fileID: DownloadableFile.ID) -> DownloadableFile {
        get { files.first { $0.id == fileID }! }
        set {
            guard let index = files.firstIndex(where: { $0.id == fileID }) else { return }
            files[index] = newValue
        }
    }
}

extension DownloadableFileGroup {
    var directoryURL: URL {
        URL.documentsDirectory
            .appending(path: "\(id.hashValue)", directoryHint: .isDirectory)
    }
}
