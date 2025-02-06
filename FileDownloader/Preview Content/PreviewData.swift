//
//  PreviewData.swift
//
//
//
//

import Foundation

extension DownloadableFileGroup {
    static let preview: DownloadableFileGroup = .init(
        id: 0,
        files: Const.exampleUrls.map { .init(url: $0) }
    )
}

extension DownloadableFile {
    static let preview = DownloadableFileGroup.preview[0]
}
