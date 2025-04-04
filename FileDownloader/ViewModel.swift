//
//  ViewModel.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation
import Observation

@Observable @MainActor
class ViewModel {
    var mediaState: MediaState?
    var downloader: SimRadioDownload?

    init(
        mediaState: MediaState,
        downloader: SimRadioDownload
    ) {
        self.mediaState = mediaState
        self.downloader = downloader
    }

    var mediaItems: [MediaView.MediaItem] {
        (mediaState?.mediaList.first?.items ?? [])
            .map {
                .init(
                    id: $0.id,
                    data: .init(
                        artwork: $0.meta.artwork,
                        title: $0.meta.title,
                        subtitle: $0.meta.listSubtitle,
                        downloadState: .progress(0.3)
                    )
                )
            }
    }

    func downloadMedia(withID id: MediaID) {
        downloader?.downloadMedia(withID: id)
    }
}
