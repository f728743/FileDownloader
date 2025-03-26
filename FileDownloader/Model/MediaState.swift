//
//  MediaState.swift
//
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Foundation
import Observation

@Observable @MainActor
class MediaState {
    var simRadio: SimRadioMedia = .empty

    var mediaList: [MediaList] {
        simRadio.series.values.map { series in
            MediaList(
                id: .simRadioSeries(series.id),
                meta: series.meta,
                items: series.stations.compactMap {
                    guard let station = simRadio.stations[$0] else { return nil }
                    return Media(
                        id: .simRadio(station.id),
                        meta: station.meta
                    )
                }
            )
        }
    }

    func load() async {
        let simRadioURLs = [
            "https://raw.githubusercontent.com/tmp-acc/GTA-V-Radio-Stations-TestDownload/master/sim_radio_stations.json"
//            "https://raw.githubusercontent.com/tmp-acc/GTA-V-Radio-Stations/master/sim_radio_stations.json"
        ].compactMap { URL(string: $0) }

        await loadSimRadio(urls: simRadioURLs)
    }
}

private extension MediaState {
    func loadSimRadio(urls: [URL]) async {
        for url in urls {
            guard let radio = try? await loadSimRadioSeries(url: url) else { continue }
            let newMedia = SimRadioMedia(dto: radio, origin: url)
            simRadio = SimRadioMedia(
                series: simRadio.series.merging(newMedia.series) { current, _ in current },
                fileGroups: simRadio.fileGroups.merging(newMedia.fileGroups) { current, _ in current },
                stations: simRadio.stations.merging(newMedia.stations) { current, _ in current }
            )
        }
    }

    func loadSimRadioSeries(url: URL) async throws -> SimRadioDTO.Series {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(SimRadioDTO.Series.self, from: data)
    }
}
