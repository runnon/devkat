import SwiftUI
import PostHog

enum PostHogEnv: String {
    case projectToken = "POSTHOG_PROJECT_TOKEN"
    case host = "POSTHOG_HOST"

    var value: String? {
        ProcessInfo.processInfo.environment[rawValue]
    }
}

@main
struct DEVKATApp: App {
    @State private var app = AppModel()
    @State private var isLaunching = true

    init() {
        if let token = PostHogEnv.projectToken.value,
           let host  = PostHogEnv.host.value {
            let config = PostHogConfig(apiKey: token, host: host)
            config.captureApplicationLifecycleEvents = true
            PostHogSDK.shared.setup(config)
        }
        // PostHog silently disabled when env vars are absent (e.g. local builds
        // without the Xcode scheme variables set).
    }

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
