import SwiftUI

@main
struct DEVKATApp: App {
    @State private var app = AppModel()
    @State private var isLaunching = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if app.isLoggedIn {
                    RootView()
                        .environment(app)
                        .preferredColorScheme(.dark)
                } else {
                    AuthView {
                        app.didSignIn()
                    }
                    .preferredColorScheme(.dark)
                }

                if isLaunching {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.35), value: isLaunching)
            .task {
                try? await Task.sleep(for: .milliseconds(600))
                isLaunching = false
            }
        }
    }
}
