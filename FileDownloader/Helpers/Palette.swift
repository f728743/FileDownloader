//
//  Palette.swift
//
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import UIKit

enum Palette {}

extension Palette {
    static let artworkBorder: UIColor = .dynamic(
        light: .black.withAlphaComponent(0.2),
        dark: .white.withAlphaComponent(0.2)
    )

    static let artworkBackground: UIColor = .dynamic(
        light: UIColor(r: 233, g: 233, b: 234, a: 255),
        dark: UIColor(r: 39, g: 39, b: 41, a: 255)
    )

    static let textTertiary: UIColor = .dynamic(
        light: UIColor(r: 127, g: 127, b: 127, a: 255),
        dark: UIColor(r: 128, g: 128, b: 128, a: 255)
    )
}

extension UIColor {
    static var palette: Palette.Type {
        Palette.self
    }
}
