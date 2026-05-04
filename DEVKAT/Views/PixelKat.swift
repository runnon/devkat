import SwiftUI

struct PixelKat: View {
    var pixelSize: CGFloat = 3
    var color: Color = .green

    var body: some View {
        Image("KatIcon")
            .renderingMode(.template)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: pixelSize * 9, height: pixelSize * 9)
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
