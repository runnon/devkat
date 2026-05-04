import SwiftUI

enum Theme {
    static let background = Color(hex: 0x000000)
    static let surface    = Color(hex: 0x0E0E0E)
    static let border     = Color(hex: 0x2A2A2A)
    static let text       = Color(hex: 0xFFFFFF)
    static let textDim    = Color(hex: 0x9A9A9A)
    static let textMuted  = Color(hex: 0x5A5A5A)

    static let logoGreen  = Color(hex: 0x00FF41)

    static let mono       = Font.system(.body,    design: .monospaced)
    static let monoSmall  = Font.system(.caption, design: .monospaced)
    static let monoLarge  = Font.system(.title2,  design: .monospaced).weight(.bold)
    static let monoHero   = Font.system(.largeTitle, design: .monospaced).weight(.bold)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
