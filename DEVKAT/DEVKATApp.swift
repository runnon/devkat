import SwiftUI
import PostHog

enum PostHogEnv: String {
    case projectToken = "POSTHOG_PROJECT_TOKEN"
    case host = "POSTHOG_HOST"

    var value: String {
        guard let value = ProcessInfo.processInfo.environment[rawValue] else {
            fatalError("Set \(rawValue) in the Xcode scheme's Run environment variables.")
        }
        return value
    }
}

@main
struct DEVKATApp: App {
    @State private var app = AppModel()
    @State private var isLaunching = true

    init() {
        let config = PostHogConfig(apiKey: PostHogEnv.projectToken.value, host: PostHogEnv.host.value)
        config.captureApplicationLifecycleEvents = true
        PostHogSDK.shared.setup(config)
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
