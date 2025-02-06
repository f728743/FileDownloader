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
        Button(
            action: { viewModel.downloadAll() },
            label: { Text("Download All") }
        )
        VStack {
            fileList
        }
    }
}

private extension ContentView {
    var fileList: some View {
        List {
            ForEach(viewModel.files) { file in
                DownloadableFileRowView(
                    file: file,
                    onDownloadToggle: { [weak viewModel] in
                        viewModel?.toggleDownload(url: file.url)
                    },
                    onCancelTapped: { [weak viewModel] in
                        viewModel?.cancelDownload(url: file.url)
                    }
                )
                .listRowInsets(.init(top: 0, leading: 16, bottom: 0, trailing: 8))
                .buttonStyle(PlainButtonStyle())
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    ContentView()
}
