//
//  ContentView.swift
//
//
//  Created by Alexey Vorobyov
//

import SwiftUI

@MainActor
struct AppDependencies {
    let mediaState: MediaState
    let simRadioDownloader: SimRadioDownload

    init() {
        mediaState = MediaState()
        simRadioDownloader = SimRadioDownload(mediaState: mediaState)
    }
}

struct ContentView: View {
    @State var dependencies: AppDependencies

    init() {
        _dependencies = State(wrappedValue: AppDependencies())
    }

    var body: some View {
        MediaView(
            dependencies: .init(
                mediaState: dependencies.mediaState,
                downloader: dependencies.simRadioDownloader
            )
        )
        .task {
            await dependencies.mediaState.load()
        }
    }
}

#Preview {
    ContentView()
}
