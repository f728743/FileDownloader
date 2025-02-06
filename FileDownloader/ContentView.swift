//
//  ContentView.swift
//
//
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
        .task { try? await viewModel.load() }
    }
}

private extension ContentView {
    var fileList: some View {
        List {
            if let group = viewModel.fileGroup {
                ForEach(group.files) { file in
                    DownloadableFileRowView(file: file) {
                        toggleDownload(for: file)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    func toggleDownload(for file: DownloadableFile) {
        if file.state == .dowloading {
            viewModel.cancelDownload(for: file)
        } else {
            Task { try? await viewModel.download(file) }
        }
    }
}

#Preview {
    ContentView()
}
