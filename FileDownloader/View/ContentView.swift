//
//  ContentView.swift
//
//
//  Created by Alexey Vorobyov
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        List {
            stationList
        }
        .listStyle(.plain)
        .task {
            await viewModel.viewTask()
        }
    }
}

private extension ContentView {
    @ViewBuilder
    var stationList: some View {
        ForEach(Array(viewModel.mediaList.items.enumerated()), id: \.offset) { offset, item in
            let isLastItem = offset == viewModel.mediaList.items.count - 1
            MediaItemView(
                artwork: item.info.artwork,
                title: item.info.title,
                subtitle: item.info.listSubtitle
            )
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

#Preview {
    ContentView()
}
