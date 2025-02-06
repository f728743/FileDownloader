//
//  Const.swift
//
//
//

import Foundation

enum Const {
    static let exampleUrls: [URL] = {
        let baseUrlStr = "https://raw.githubusercontent.com/tmp-acc/GTA-V-Radio-Stations/master/"
        let fileNames: [String] = [
            "radio_08_mexican/mex_final_mix_32.m4a",
            "radio_13_jazz/wwfm_p1.m4a",
            "radio_13_jazz/wwfm_p2.m4a",
            "radio_05_talk_01/mono_chakra_attack_part_1.m4a"
        ]
        return fileNames.compactMap { URL(string: baseUrlStr + $0) }
    }()
}
