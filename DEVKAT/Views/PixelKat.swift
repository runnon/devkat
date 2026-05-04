import SwiftUI

struct PixelKat: View {
    var pixelSize: CGFloat = 3
    var color: Color = .green

    private static let pattern: [String] = [
        "1.......1",
        "11.....11",
        "111111111",
        "1.1...1.1",
        "111111111",
        ".1111111.",
        "..11.11..",
    ]

    var body: some View {
        Canvas { ctx, _ in
            for (row, line) in Self.pattern.enumerated() {
                for (col, c) in line.enumerated() {
                    guard c == "1" else { continue }
                    let rect = CGRect(
                        x: CGFloat(col) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(
            width:  CGFloat(Self.pattern[0].count) * pixelSize,
            height: CGFloat(Self.pattern.count)    * pixelSize
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 24) {
            PixelKat(pixelSize: 6, color: Color(red: 0, green: 1, blue: 0.255))
            PixelKat(pixelSize: 4, color: Color(red: 0, green: 1, blue: 0.255))
            PixelKat(pixelSize: 2, color: Color(red: 0, green: 1, blue: 0.255))
        }
    }
}
