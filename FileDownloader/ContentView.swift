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
    }
}

private extension ContentView {
    var fileList: some View {
        List {
            ForEach(viewModel.files) { file in
                DownloadableFileRowView(file: file)
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    ContentView()
}
