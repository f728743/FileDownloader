//
//  View+Extensions.swift
//
//
//  Created by Alexey Vorobyov on 29.03.2025.
//

import SwiftUI

private let rainbowDebugColors = [Color.purple, Color.blue, Color.green, Color.yellow, Color.orange, Color.red]

extension View {
    func rainbowDebug() -> some View {
        background(rainbowDebugColors.randomElement()!)
    }
}
