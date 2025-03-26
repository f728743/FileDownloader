//
//  Comparable+Extensions.swift
//  FileDownloader
//
//  Created by Alexey Vorobyov on 03.04.2025.
//

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
