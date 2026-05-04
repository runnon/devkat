import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HStack(alignment: .center, spacing: 8) {
                Text("DEVKAT")
                    .font(.custom("Baskerville", size: 26).weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}
