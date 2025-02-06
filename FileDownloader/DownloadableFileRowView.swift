//
//  DownloadableFileRowView.swift
//
//
//

import SwiftUI

struct DownloadableFileRowView: View {
    let file: DownloadInfo

    var body: some View {
        HStack(alignment: .top) {
            image
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6.0) {
                Text(file.details)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                ProgressView(value: file.progress)
            }
        }
    }

    @ViewBuilder
    var image: some View {
        switch file.status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(UIColor.systemGreen))

        case .downloading:
            Image(systemName: "progress.indicator")
                .foregroundStyle(Color(UIColor.systemGray))
                .symbolEffect(.variableColor.iterative)
        default:
            Image(systemName: "arrow.down")
                .foregroundStyle(Color(UIColor.systemBlue))
        }
    }
}

private extension DownloadInfo {
    var details: String {
        url.pathComponents.suffix(2).joined(separator: "/")
    }
}

 #Preview {
     @Previewable @State var file0 = DownloadInfo(url: URL(filePath: "storage/movie01.mp4")!, status: .downloading)
     @Previewable @State var file1 = DownloadInfo(url: URL(filePath: "storage/movie02.mp4")!, status: .queued)
    List {
        DownloadableFileRowView(file: file0)
        DownloadableFileRowView(file: file1)
    }
    .onAppear {
        file0.update(currentBytes: 50, totalBytes: 100)
    }
    .listStyle(.plain)
 }
