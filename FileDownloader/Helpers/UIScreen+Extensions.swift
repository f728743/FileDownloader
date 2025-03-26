//
//  UIScreen+Extensions.swift
//
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import UIKit

extension UIScreen {
    static var deviceCornerRadius: CGFloat {
        main.value(forKey: "_displayCornerRadius") as? CGFloat ?? 0
    }

    static var hairlineWidth: CGFloat {
        1 / main.scale
    }
}
