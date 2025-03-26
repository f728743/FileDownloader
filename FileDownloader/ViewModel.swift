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
    var simRadioDownloader: SimRadioDownloadService?

    init(
        mediaState: MediaState,
        simRadioDownloader: SimRadioDownloadService
    ) {
        self.mediaState = mediaState
        self.simRadioDownloader = simRadioDownloader
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
        simRadioDownloader?.downloadMedia(withID: id)
    }
}
