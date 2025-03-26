//
//  MediaItemView.swift
//
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Kingfisher
import SwiftUI

struct MediaItemView: View {
    let artwork: URL?
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            let border = UIScreen.hairlineWidth
            KFImage.url(artwork)
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
                Text(title)
                    .font(.system(size: 16))
                Text(subtitle ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.palette.textTertiary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
        }
        .padding(.top, 4)
        .frame(height: 56, alignment: .top)
    }
}
