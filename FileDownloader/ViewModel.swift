//
//  ViewModel.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation

@MainActor
class ViewModel: ObservableObject {
    @Published var files: [DownloadInfo] = Config.files.map { DownloadInfo(url: $0, state: .pending) }
    static let list = Const.largeFiles
    private var downloader = DownloadQueue(maxConcurrentDownloads: 2)

    init() {
        Task {
            for await event in downloader.events {
                process(event)
            }
        }
    }

    func toggleDownload(url: URL) {
        Task {
            if let file = files.first(where: { $0.url == url }), file.state == .downloading {
                await downloader.cancelDownload(url: url, pausing: true)
            } else {
                await downloader.downloadFile(from: url)
            }
        }
    }

    func cancelDownload(url: URL) {
        Task {
            await downloader.cancelDownload(url: url, pausing: false)
        }
    }

    func downloadAll() {
        Task {
            await downloader.downloadFiles(from: Config.files)
        }
    }

    enum Config {
        static let files = Const.largeFiles
    }
}

private extension ViewModel {
    func process(_ event: DownloadQueue.Event) {
        guard let index = files.firstIndex(where: { $0.url == event.url }) else { return }
        files[index].update(state: event.state.downloadInfoState)

        switch event.state {
        case .queued:
            files[index].update(currentBytes: 0)
        case let .completed(localURL):
            print("Downloaded", localURL.path)
        case let .progress(currentBytes, totalBytes):
            files[index].update(currentBytes: currentBytes, totalBytes: totalBytes)
        case let .failed(error):
            print("Error", error.localizedDescription)
        default: break
        }
    }
}

extension DownloadQueue.DownloadState {
    var downloadInfoState: DownloadInfo.State {
        switch self {
        case .queued: .queued
        case .progress: .downloading
        case .completed: .completed
        case .canceled: .pending
        case .paused: .paused
        case .failed: .failed
        }
    }
}
