import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HStack(alignment: .center, spacing: 8) {
                Text("DEVKAT")
                    .font(.custom("LEDLIGHT", size: 26).weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}
