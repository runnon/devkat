import SwiftUI

struct PixelText: View {
    let text: String
    var pixelSize: CGFloat = 4
    var color: Color = .white
    var letterSpacing: Int = 1

    private static let glyphWidth  = 5
    private static let glyphHeight = 7

    private static let glyphs: [Character: [String]] = [
        "D": ["11110",
              "10001",
              "10001",
              "10001",
              "10001",
              "10001",
              "11110"],
        "E": ["11111",
              "10000",
              "10000",
              "11110",
              "10000",
              "10000",
              "11111"],
        "V": ["10001",
              "10001",
              "10001",
              "10001",
              "10001",
              "01010",
              "00100"],
        "K": ["10001",
              "10010",
              "10100",
              "11000",
              "10100",
              "10010",
              "10001"],
        "A": ["01110",
              "10001",
              "10001",
              "11111",
              "10001",
              "10001",
              "10001"],
        "T": ["11111",
              "00100",
              "00100",
              "00100",
              "00100",
              "00100",
              "00100"],
    ]

    private var characters: [Character] { Array(text.uppercased()) }

    private var totalGridWidth: Int {
        let n = characters.count
        guard n > 0 else { return 0 }
        return n * Self.glyphWidth + (n - 1) * letterSpacing
    }

    var body: some View {
        Canvas { ctx, _ in
            for (idx, ch) in characters.enumerated() {
                guard let glyph = Self.glyphs[ch] else { continue }
                let xOffset = CGFloat(idx * (Self.glyphWidth + letterSpacing)) * pixelSize
                for (row, line) in glyph.enumerated() {
                    for (col, c) in line.enumerated() {
                        guard c == "1" else { continue }
                        let rect = CGRect(
                            x: xOffset + CGFloat(col) * pixelSize,
                            y: CGFloat(row) * pixelSize,
                            width: pixelSize,
                            height: pixelSize
                        )
                        ctx.fill(Path(rect), with: .color(color))
                    }
                }
            }
        }
        .frame(
            width:  CGFloat(totalGridWidth)    * pixelSize,
            height: CGFloat(Self.glyphHeight)  * pixelSize
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 24) {
            PixelText(text: "DEVKAT", pixelSize: 6, color: Color(red: 0, green: 1, blue: 0.255))
            PixelText(text: "DEVKAT", pixelSize: 4, color: Color(red: 0, green: 1, blue: 0.255))
            PixelText(text: "DEVKAT", pixelSize: 3, color: Color(red: 0, green: 1, blue: 0.255))
        }
    }
}
