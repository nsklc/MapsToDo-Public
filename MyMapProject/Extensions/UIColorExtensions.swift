//
//  UIColorExtensions.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 10.11.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import UIKit
// swiftlint:disable identifier_name
extension UIColor {
    enum HexFormat {
        case RGB
        case ARGB
        case RGBA
        case RRGGBB
        case AARRGGBB
        case RRGGBBAA
        case AABBGGRR
    }

    enum HexDigits {
        case d3, d4, d6, d8
    }

    func hexString(_ format: HexFormat = .RRGGBBAA) -> String {
        let maxi = [.RGB, .ARGB, .RGBA].contains(format) ? 16 : 256

        func toI(_ f: CGFloat) -> Int {
            min(maxi - 1, Int(CGFloat(maxi) * f))
        }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        let ri = toI(r)
        let gi = toI(g)
        let bi = toI(b)
        let ai = toI(a)

        switch format {
        case .RGB:       return String(format: "#%X%X%X", ri, gi, bi)
        case .ARGB:      return String(format: "#%X%X%X%X", ai, ri, gi, bi)
        case .RGBA:      return String(format: "#%X%X%X%X", ri, gi, bi, ai)
        case .RRGGBB:    return String(format: "#%02X%02X%02X", ri, gi, bi)
        case .AARRGGBB:  return String(format: "#%02X%02X%02X%02X", ai, ri, gi, bi)
        case .RRGGBBAA:  return String(format: "#%02X%02X%02X%02X", ri, gi, bi, ai)
        case .AABBGGRR: return String(format: "%02X%02X%02X%02X", ai, bi, gi, ri)
        }
    }

    func hexString(_ digits: HexDigits) -> String {
        switch digits {
        case .d3: return hexString(.RGB)
        case .d4: return hexString(.RGBA)
        case .d6: return hexString(.RRGGBB)
        case .d8: return hexString(.RRGGBBAA)
        }
    }
}
