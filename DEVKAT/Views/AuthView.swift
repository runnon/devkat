import SwiftUI

struct AuthView: View {
    var onAuthenticated: () -> Void

    @State private var email    = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var animateBars = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Visual — hours bar chart
                HoursChart(animate: $animateBars)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .padding(.horizontal, 32)
                    .padding(.top, 60)

                Spacer(minLength: 0)

                // Logo + tagline
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        PixelKat(pixelSize: 3, color: Theme.logoGreen)
                        PixelText(text: "DEVKAT", pixelSize: 3, color: Theme.logoGreen)
                    }
                    Text("your sessions, made shareable")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.bottom, 36)

                // Form
                VStack(spacing: 12) {
                    field(placeholder: "Email", text: $email, keyboard: .emailAddress)
                    field(placeholder: "Password", text: $password, secure: true)

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }

                    Button(action: submit) {
                        ZStack {
                            if isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text(isSignUp ? "CREATE ACCOUNT" : "SIGN IN")
                                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                                    .tracking(2)
                                    .foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.top, 8)

                    Button {
                        isSignUp.toggle()
                        errorMessage = nil
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign in" : "No account? Create one")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Theme.textDim)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0)) {
                    animateBars = true
                }
            }
        }
    }

    private func field(placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, secure: Bool = false) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .font(.system(.body, design: .monospaced))
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func submit() {
        guard !email.isEmpty, !password.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let tokens: AuthTokens
                if isSignUp {
                    tokens = try await SupabaseService.shared.signUp(email: email, password: password)
                } else {
                    tokens = try await SupabaseService.shared.signIn(email: email, password: password)
                }
                tokens.persist()
                await MainActor.run { onAuthenticated() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: – Hours Chart

private struct HoursChart: View {
    @Binding var animate: Bool

    // Representative week of session hours per day — Mon through Sun
    private let days: [(label: String, hours: Double, sessions: Int)] = [
        ("M", 1.8, 2),
        ("T", 4.2, 3),
        ("W", 2.5, 2),
        ("T", 6.7, 4),
        ("F", 5.3, 3),
        ("S", 3.1, 2),
        ("S", 0.8, 1),
    ]

    private var maxHours: Double { days.map(\.hours).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // y-axis label
            Text("HOURS THIS WEEK")
                .font(.system(size: 9, design: .monospaced).weight(.bold))
                .foregroundStyle(Theme.textMuted)
                .tracking(2)

            // Bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                    let fraction = day.hours / maxHours
                    let isPeak   = day.hours == maxHours

                    VStack(spacing: 6) {
                        // Session count dot
                        if day.sessions > 1 {
                            HStack(spacing: 2) {
                                ForEach(0..<min(day.sessions, 4), id: \.self) { _ in
                                    Circle()
                                        .fill(isPeak ? Theme.logoGreen : Color.white.opacity(0.25))
                                        .frame(width: 3, height: 3)
                                }
                            }
                            .opacity(animate ? 1 : 0)
                        } else {
                            Color.clear.frame(width: 3, height: 3)
                        }

                        GeometryReader { geo in
                            let maxH = geo.size.height
                            let barH = animate ? maxH * fraction : 0

                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                ZStack(alignment: .top) {
                                    // Bar body
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(
                                            isPeak
                                            ? LinearGradient(colors: [Theme.logoGreen, Theme.logoGreen.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                                        )
                                        .frame(height: barH)
                                        .animation(.spring(response: 0.7, dampingFraction: 0.72).delay(Double(i) * 0.06), value: animate)

                                    // Hour label inside top of bar (only when tall enough)
                                    if day.hours >= 2 {
                                        Text(String(format: "%.0fh", day.hours))
                                            .font(.system(size: 8, design: .monospaced).weight(.medium))
                                            .foregroundStyle(isPeak ? Color.black.opacity(0.7) : Color.white.opacity(0.5))
                                            .padding(.top, 5)
                                            .opacity(animate ? 1 : 0)
                                            .animation(.easeIn(duration: 0.3).delay(Double(i) * 0.06 + 0.4), value: animate)
                                    }
                                }
                            }
                        }

                        // Day label
                        Text(day.label)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(isPeak ? Theme.logoGreen : Theme.textMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Total
            let totalH = days.map(\.hours).reduce(0, +)
            Text(String(format: "%.1f hrs", totalH))
                .font(.system(size: 11, design: .monospaced).weight(.semibold))
                .foregroundStyle(Theme.textDim)
                .opacity(animate ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.7), value: animate)
        }
    }
}

