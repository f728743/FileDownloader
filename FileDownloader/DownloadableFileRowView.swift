//
//  DownloadableFileRowView.swift
//
//
//

import SwiftUI

struct DownloadableFileRowView: View {
    let file: DownloadableFile
    let onButtonPressed: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16.0) {
            Button(action: onButtonPressed) {
                Image(systemName: file.buttonImageName)
                    .font(.title3)
                    .frame(width: 24.0, height: 32.0)
            }
            .buttonStyle(.bordered)
            VStack(alignment: .leading, spacing: 6.0) {
                Text(file.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if file.progress > 0 && !file.isDownloadCompleted {
                    ProgressView(value: file.progress)
                }
            }
        }
        .padding(.top, 8.0)
        .padding(.bottom, 4.0)
    }
}

private extension DownloadableFile {
    var details: String {
        url.pathComponents.suffix(2).joined(separator: "/")
    }

    var buttonImageName: String {
        switch (isDownloadCompleted, state) {
        case (true, _): return "checkmark.circle.fill"
        case (false, .dowloading): return "pause.fill"
        case (false, _): return "tray.and.arrow.down"
        }
    }
}

#Preview {
    List {
        DownloadableFileRowView(file: .preview, onButtonPressed: {})
    }
    .listStyle(.plain)
}
