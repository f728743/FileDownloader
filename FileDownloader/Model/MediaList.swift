//
//  MediaList.swift
//
//
//  Created by Alexey Vorobyov on 29.03.2025.
//

import Foundation

struct MediaList: Identifiable {
    let id: MediaListID
    let meta: Meta
    let items: [Media]

    struct Meta {
        let artwork: URL?
        let title: String
        let subtitle: String?
    }
}

struct Media: Identifiable {
    let id: MediaID
    let meta: Meta

    struct Meta: Equatable, Hashable {
        let artwork: URL?
        let title: String
        let listSubtitle: String?
        let detailsSubtitle: String?
        let online: Bool
    }
}

enum MediaListID: Hashable {
    case emptyMediaListID
    case simRadioSeries(SimSeries.ID)
}

enum MediaID: Hashable {
    case simRadio(SimStation.ID)
}

extension MediaList {
    static let empty: MediaList = .init(
        id: .emptyMediaListID,
        meta: .init(
            artwork: nil,
            title: "",
            subtitle: nil
        ),
        items: []
    )
}
