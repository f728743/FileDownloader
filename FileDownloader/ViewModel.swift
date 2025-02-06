//
//  ViewModel.swift
//
//
//

import Foundation

@MainActor
class ViewModel: ObservableObject {
    @Published var fileGroup: DownloadableFileGroup?

    private var downloads: [URL: Download] = [:]

    func load() async throws {
        fileGroup = .init(id: 0, files: Const.exampleUrls.map { .init(url: $0) })
    }

    func downloadAll() {
        fileGroup?.files.forEach { file in
            Task {
                try await download(file)
            }
        }
    }

    func download(_ file: DownloadableFile) async throws {
        guard downloads[file.url] == nil,
              !file.isDownloadCompleted
        else { return }
        let download = if case let .canceled(data) = file.state {
            Download(resumeData: data)
        } else {
            Download(url: file.url)
        }
        downloads[file.url] = download
        download.start()
        fileGroup?[file.id].state = .dowloading
        for await event in download.events {
            process(event, for: file)
        }
        downloads[file.url] = nil
    }

    func cancelDownload(for file: DownloadableFile) {
        downloads[file.url]?.cancel()
        fileGroup?[file.id].state = .idle
    }
}

private extension ViewModel {
    func process(_ event: Download.Event, for file: DownloadableFile) {
        switch event {
        case let .progress(current, total):
            fileGroup?[file.id].update(currentBytes: current, totalBytes: total)
        case let .completed(url):
            saveFile(for: file, at: url)
            fileGroup?[file.id].state = .completed
        case let .canceled(data):
            fileGroup?[file.id].state = if let data {
                .canceled(resumeData: data)
            } else {
                .idle
            }
        }
    }

    func saveFile(for file: DownloadableFile, at url: URL) {
        guard let directoryURL = fileGroup?.directoryURL else { return }
        let filemanager = FileManager.default
        if !filemanager.fileExists(atPath: directoryURL.path()) {
            try? filemanager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        try? filemanager.moveItem(at: url, to: file.fileURL)
    }
}
