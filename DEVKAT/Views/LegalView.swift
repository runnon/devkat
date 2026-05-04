import SwiftUI

struct LegalView: View {
    let title: String
    let sections: [LegalSection]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                        .padding(.bottom, 8)

                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            if let heading = section.heading {
                                Text(heading)
                                    .font(.system(.subheadline, design: .default).weight(.semibold))
                                    .foregroundStyle(Theme.text)
                            }
                            Text(section.body)
                                .font(.system(.subheadline, design: .default))
                                .foregroundStyle(Theme.textDim)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 60)
            }
        }
    }

    private var header: some View {
        ZStack {
            Text(title)
                .font(.system(.body, design: .default).weight(.semibold))
                .foregroundStyle(Theme.text)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textDim)
                        .frame(width: 32, height: 32)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
        .padding(.top, 8)
    }
}

struct LegalSection: Identifiable {
    let id = UUID()
    let heading: String?
    let body: String

    init(_ heading: String? = nil, _ body: String) {
        self.heading = heading
        self.body = body
    }
}

// MARK: - Documents

enum LegalDocuments {

    static let effectiveDate = "May 4, 2026"

    static var privacyPolicy: [LegalSection] {
        [
            LegalSection(
                nil,
                "Effective date: \(effectiveDate)\n\nDevkat (\"we\", \"our\", \"the app\") turns your AI coding sessions into shareable visual cards. This policy explains what data we collect, how we use it, and the controls you have."
            ),
            LegalSection(
                "1. Data We Collect",
                """
                Account credentials. When you sign up we store your email address and a securely hashed password via Supabase Auth. We never see or store your plaintext password.

                Session statistics. When you push a session from your machine, we receive aggregate stats only: duration, lines added/removed, file count, token usage, model name, and timestamps. We do not receive source code, file contents, file paths, environment variables, or prompt/response text.

                Device information. We may collect basic device identifiers (iOS version, device model) for crash reporting and analytics. This data is anonymised and cannot be linked to your source code.
                """
            ),
            LegalSection(
                "2. Data We Never Collect",
                """
                Source code or diffs. Devkat's CLI parser computes statistics locally on your machine. Raw code never leaves your device.

                File paths. Paths are counted but not transmitted. The "Scope" stat is a number, not a list of filenames.

                Secrets or credentials. The CLI does not read .env files, API keys, or tokens from your codebase. A pre-flight scan strips any secrets that might appear in session metadata before upload.

                Prompt or response text. The content of your conversations with AI assistants is never sent to our servers.
                """
            ),
            LegalSection(
                "3. How We Use Your Data",
                """
                Display your sessions. Statistics are stored so you can view your session history and generate overlay cards within the app.

                Improve the product. We may use anonymised, aggregate usage patterns (e.g. average session length across all users) to improve Devkat. We will never sell individual data or share it with third parties for advertising.
                """
            ),
            LegalSection(
                "4. Image Composition & Sharing",
                """
                Overlay cards are rendered entirely on your device. When you copy or save an image, it goes to your local clipboard or camera roll. Devkat does not upload, store, or have access to the images you create. What you share and where you share it is entirely your choice.
                """
            ),
            LegalSection(
                "5. Data Storage & Security",
                """
                Your session data is stored in Supabase (hosted on AWS) with row-level security — each user can only access their own records. Auth tokens are stored in your device's Keychain. All network communication uses TLS 1.2+.
                """
            ),
            LegalSection(
                "6. Data Retention & Deletion",
                """
                You can delete your account at any time from Settings. When you delete your account, all associated session data is permanently removed from our servers. There is no recovery period — deletion is immediate and irreversible.
                """
            ),
            LegalSection(
                "7. Third-Party Services",
                """
                Supabase — authentication and database hosting.
                Apple — app distribution, crash reporting via Xcode Organizer.

                We do not use any third-party analytics SDKs, advertising networks, or tracking pixels.
                """
            ),
            LegalSection(
                "8. Children's Privacy",
                "Devkat is not directed at children under 13. We do not knowingly collect information from children under 13. If you believe a child has provided us with personal data, please contact us and we will delete it."
            ),
            LegalSection(
                "9. Changes to This Policy",
                "We may update this policy from time to time. If we make material changes, we will notify you through the app or via email. Your continued use of Devkat after changes take effect constitutes acceptance of the updated policy."
            ),
            LegalSection(
                "10. Contact",
                "Questions or concerns? Reach us at support@devkat.app."
            ),
        ]
    }

    static var termsOfService: [LegalSection] {
        [
            LegalSection(
                nil,
                "Effective date: \(effectiveDate)\n\nBy using Devkat you agree to these terms. If you don't agree, please don't use the app."
            ),
            LegalSection(
                "1. What Devkat Does",
                "Devkat parses aggregate statistics from your AI coding sessions and displays them as visual overlay cards. The app does not access, read, store, or transmit your source code."
            ),
            LegalSection(
                "2. Your Account",
                """
                You must provide a valid email to create an account. You're responsible for keeping your credentials secure. One account per person — don't share your login. We reserve the right to suspend accounts that violate these terms.
                """
            ),
            LegalSection(
                "3. Your Data, Your Responsibility",
                """
                Session statistics you push to Devkat belong to you. You grant us a limited license to store and display this data back to you within the app. We don't claim ownership of your data.

                The images you create with Devkat are yours. You're responsible for ensuring anything you share publicly doesn't contain sensitive information. While Devkat includes redaction features, you should always review a card before posting it.
                """
            ),
            LegalSection(
                "4. Acceptable Use",
                """
                Don't use Devkat to:
                • Reverse-engineer, decompile, or disassemble the app.
                • Attempt to access other users' data.
                • Automate access in a way that degrades the service for others.
                • Distribute malicious content through any sharing feature.
                """
            ),
            LegalSection(
                "5. Intellectual Property",
                "The Devkat name, logo, pixel cat mascot, overlay templates, and app design are our intellectual property. Your session data and generated images are yours."
            ),
            LegalSection(
                "6. Service Availability",
                "We aim to keep Devkat available and reliable, but we don't guarantee 100% uptime. We may pause the service for maintenance, updates, or circumstances beyond our control. We'll try to give advance notice when possible."
            ),
            LegalSection(
                "7. Limitation of Liability",
                "Devkat is provided \"as is\" without warranties of any kind. We're not liable for any indirect, incidental, or consequential damages arising from your use of the app. Our total liability is limited to the amount you've paid us in the 12 months preceding the claim (which, for a free app, is zero)."
            ),
            LegalSection(
                "8. Termination",
                "You can stop using Devkat and delete your account at any time. We may also terminate or suspend your access if you violate these terms. On termination, your data is deleted per our Privacy Policy."
            ),
            LegalSection(
                "9. Changes to These Terms",
                "We may update these terms. Material changes will be communicated through the app. Continued use after changes means you accept the new terms."
            ),
            LegalSection(
                "10. Governing Law",
                "These terms are governed by the laws of the United States. Any disputes will be resolved in the courts of New York, NY."
            ),
            LegalSection(
                "11. Contact",
                "Questions? Reach us at support@devkat.app."
            ),
        ]
    }
}
