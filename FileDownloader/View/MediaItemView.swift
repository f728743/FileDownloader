//
//  MediaItemView.swift
//
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Kingfisher
import SwiftUI

struct MediaItemView: View {
    enum DownloadState {
        case progress(Double)
        case downloaded
    }

    struct Item {
        let artwork: URL?
        let title: String
        let subtitle: String?
        let downloadState: DownloadState?
    }

    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            let border = UIScreen.hairlineWidth
            KFImage.url(item.artwork)
                .resizable()
                .frame(width: 48, height: 48)
                .aspectRatio(contentMode: .fill)
                .background(Color(.palette.artworkBackground))
                .clipShape(.rect(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .inset(by: border / 2)
                        .stroke(Color(.palette.artworkBorder), lineWidth: border)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 16))
                Text(item.subtitle ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.palette.textTertiary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            downloadIndicator
        }
        .padding(.top, 4)
        .frame(height: 56, alignment: .top)
    }
}

private extension MediaItemView {
    @ViewBuilder
    var downloadIndicator: some View {
        if let downloadState = item.downloadState {
            switch downloadState {
            case let .progress(progress):
                ProgressView(value: progress)
                    .frame(width: 48, height: 8)
                    .cornerRadius(4)
            case .downloaded:
                Color.red
                    .frame(width: 48, height: 8)
                    .cornerRadius(4)
            }
        }
    }
}
