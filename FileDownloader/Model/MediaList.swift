//
//  MediaList.swift
//
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Foundation

struct MediaList: Identifiable, Equatable, Hashable {
    let id = UUID()
    let artwork: URL?
    let title: String
    let subtitle: String?
    let items: [Media]
}

struct Media: Identifiable, Equatable, Hashable {
    let id = UUID()
    let artwork: URL?
    let title: String
    let subtitle: String?
    let online: Bool
}

extension MediaList {
    static let empty: MediaList = .init(
        artwork: nil,
        title: "",
        subtitle: nil,
        items: []
    )

    init(from series: SimRadio.Series, baseUrl: String) {
        self.init(
            artwork: URL(string: "\(baseUrl)/\(series.info.logo)"),
            title: series.info.title,
            subtitle: nil,
            items: series.stations.map { .init(from: $0, baseUrl: baseUrl) }
        )
    }
}

extension Media {
    init(from station: SimRadio.Station, baseUrl: String) {
        title = station.info.title
        subtitle = station.info.genre
        let artwork = "\(baseUrl)/\(station.tag)/\(station.info.logo)"
        self.artwork = URL(string: artwork)
        online = false
    }
}
