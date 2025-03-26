//
//  MediaView.swift
//
//
//  Created by Alexey Vorobyov on 29.03.2025.
//

import SwiftUI

struct MediaView: View {
    @State private var viewModel: ViewModel

    init(dependencies: Dependencies) {
        _viewModel = State(
            wrappedValue: ViewModel(
                mediaState: dependencies.mediaState,
                downloader: dependencies.downloader
            )
        )
    }

    var body: some View {
        List {
            stationList
        }
        .listStyle(.plain)
    }

    struct Dependencies {
        let mediaState: MediaState
        let downloader: SimRadioDownload
    }

    struct MediaItem {
        let id: MediaID
        let data: MediaItemView.Item
    }
}

private extension MediaView {
    @ViewBuilder
    var stationList: some View {
        ForEach(Array(viewModel.mediaItems.enumerated()), id: \.offset) { offset, item in
            let isLastItem = offset == viewModel.mediaItems.count - 1
            MediaItemView(item: item.data)
                .contentShape(.rect)
                .listRowInsets(.screenInsets)
                .alignmentGuide(.listRowSeparatorLeading) {
                    isLastItem ? $0[.leading] : $0[.leading] + 60
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        viewModel.downloadMedia(withID: item.id)
                    } label: {
                        Label("Download", systemImage: "arrow.down")
                    }
                    .tint(.init(.systemBlue))
                }
        }
    }
}

private extension EdgeInsets {
    static let screenInsets: EdgeInsets = .init(
        top: 0, leading: 20, bottom: 0, trailing: 20
    )
}
