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
        switch file.state {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(UIColor.systemGreen))
        case .downloading:
            Image(systemName: "arrow.down")
                .foregroundStyle(Color(UIColor.systemBlue))
                .frame(width: 24, height: 24)
                .phaseAnimator([true, false]) { content, phase in
                    content.offset(y: phase ? 20 : -20)
                } animation: { phase in
                    phase ? .linear(duration: 0.5) : nil
                }
                .clipped()
        case .paused:
            Image(systemName: "pause.circle")
                .foregroundStyle(Color(UIColor.systemGray))
        case .pending:
            Image(systemName: "arrow.down")
                .foregroundStyle(Color(UIColor.systemGray))
        case .queued:
            Image(systemName: "progress.indicator")
                .foregroundStyle(Color(UIColor.systemGray))
                .symbolEffect(.variableColor.iterative)
        case .failed:
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundStyle(Color(UIColor.systemRed))
        }
    }
}

private extension DownloadInfo {
    var details: String {
        url.pathComponents.suffix(2).joined(separator: "/")
    }
}

#Preview {
    @Previewable @State var file0 = DownloadInfo(url: URL(filePath: "storage/movie01.mp4")!, state: .downloading)
    @Previewable @State var file1 = DownloadInfo(url: URL(filePath: "storage/movie02.mp4")!, state: .paused)
    @Previewable @State var file2 = DownloadInfo(url: URL(filePath: "storage/movie03.mp4")!, state: .failed)
    List {
        DownloadableFileRowView(file: file0)
        DownloadableFileRowView(file: file1)
        DownloadableFileRowView(file: file2)
    }
    .onAppear {
        file0.update(currentBytes: 50, totalBytes: 100)
        file1.update(currentBytes: 33, totalBytes: 100)
    }
    .listStyle(.plain)
}
