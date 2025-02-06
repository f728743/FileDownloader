//
//  ViewModel.swift
//
//
//

import Foundation

@MainActor
class ViewModel: ObservableObject {
    @Published var files: [DownloadInfo] = Config.files.map { DownloadInfo(url: $0, status: .queued) }
    static let list = Const.largeFiles
    private var downloader = DownloadQueue(maxConcurrentDownloads: 2)

    func downloadAll() {
        downloader.startDownloads(urls: Config.files)
        Task {
            for await event in downloader.events {
                process(event)
            }
        }
    }

    enum Config {
        static let files = Const.largeFiles
    }
}

private extension ViewModel {
    func process(_ event: DownloadQueue.Event) {
        guard let index = files.firstIndex(where: { $0.url == event.url }) else { return }
        switch event.event {
        case .canceled:
            files[index].update(status: .queued)
        case let .completed(lacalURL):
            files[index].update(status: .completed)
            print(lacalURL.path)
        case let .progress(currentBytes, totalBytes):
            files[index].update(status: .downloading)
            files[index].update(currentBytes: currentBytes, totalBytes: totalBytes)
        }
    }
}
