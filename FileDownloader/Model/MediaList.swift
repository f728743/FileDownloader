//
//  MediaList.swift
//
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Foundation

struct MediaListInfo {
    let artwork: URL?
    let title: String
    let subtitle: String?
}

struct MediaList: Identifiable {
    let id: MediaListID
    let info: MediaListInfo
    let items: [Media]
}

struct MediaInfo: Equatable, Hashable {
    let artwork: URL?
    let title: String
    let listSubtitle: String?
    let detailsSubtitle: String?
    let online: Bool
}

struct Media: Identifiable {
    let id: MediaID
    let info: MediaInfo
}

enum MediaListID: Hashable {
    case emptyMediaListID
    case simRadioSeries(SimSeries.ID)
}

enum MediaID: Hashable {
    case simRadio(SimStation.ID)
}

struct MediaState {
    let simRadio: SimRadioMedia
}

extension MediaState {
    var mediaList: [MediaList] {
        simRadio.series.values.map { series in
            .init(
                id: .simRadioSeries(series.id),
                info: series.info,
                items: series.stations.compactMap {
                    guard let station = simRadio.stations[$0] else { return nil }
                    return Media(
                        id: .simRadio(station.id),
                        info: station.info
                    )
                }
            )
        }
    }
}

extension MediaState {
    static let empty: MediaState = .init(
        simRadio: .init(
            series: [:],
            fileGroups: [:],
            stations: [:]
        )
    )
}

extension MediaList {
    static let empty: MediaList = .init(
        id: .emptyMediaListID,
        info: .init(
            artwork: nil,
            title: "",
            subtitle: nil
        ),
        items: []
    )
}
