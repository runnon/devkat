import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app
    @State private var selected: Tab = .home

    enum Tab: String, CaseIterable, Hashable {
        case home, copy

        var selectedIcon: String {
            switch self {
            case .home: "house.fill"
            case .copy: "plus.square.on.square.fill"
            }
        }

        var unselectedIcon: String {
            switch self {
            case .home: "house"
            case .copy: "plus.square.on.square"
            }
        }

        var label: String {
            switch self {
            case .home: "Home"
            case .copy: "Overlays"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            ZStack {
                HomeView(
                    onCopyTap: {
                        selectTab(.copy)
                    },
                    onSessionTap: { session in
                        app.selectedSession = session
                        selected = .copy
                    }
                )
                .opacity(selected == .home ? 1 : 0)
                .allowsHitTesting(selected == .home)

                CopyView()
                    .opacity(selected == .copy ? 1 : 0)
                    .allowsHitTesting(selected == .copy)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)

            HStack(spacing: 72) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        selectTab(tab)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: selected == tab ? tab.selectedIcon : tab.unselectedIcon)
                                .font(.system(size: 22, weight: selected == tab ? .medium : .light))
                            Text(tab.label)
                                .font(.system(size: 10, weight: selected == tab ? .semibold : .regular))
                        }
                        .foregroundStyle(selected == tab
                                         ? .white
                                         : Color.white.opacity(0.45))
                        .frame(width: 64, height: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
        .background(
            ZStack {
                BlurView(style: .systemMaterialDark)
                Color.black.opacity(0.4)
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func selectTab(_ tab: Tab) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) {
            selected = tab
        }
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
