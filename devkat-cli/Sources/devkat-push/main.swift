import Foundation
import DevKatParser

let args = CommandLine.arguments
let home = FileManager.default.homeDirectoryForCurrentUser
let claudeDir = home.appendingPathComponent(".claude")

func run() {
    if args.contains("--login")  { return runLogin() }
    if args.contains("--logout") { return runLogout() }
    if args.contains("--list")   { return listSessions() }

    let sessionURL: URL
    if let idx = args.firstIndex(of: "--session"), args.count > idx + 1 {
        sessionURL = URL(fileURLWithPath: args[idx + 1])
    } else {
        guard let latest = findLatestSessionFile(in: claudeDir) else {
            print("devkat-push: no Claude Code session files found in ~/.claude/projects/")
            exit(1)
        }
        sessionURL = latest
    }

    print("devkat-push: parsing \(sessionURL.lastPathComponent) …")

    do {
        let session = try parseSession(at: sessionURL)
        try writeSession(session)
        printSummary(session)
    } catch {
        print("devkat-push: error – \(error.localizedDescription)")
        exit(1)
    }
}

// MARK: - Login

func runLogin() {
    print("devkat-push: Supabase login")
    print("  (no account yet? enter 'signup' as the password to create one)")
    print()

    print("Email: ", terminator: "")
    guard let email = readLine()?.trimmingCharacters(in: .whitespaces), !email.isEmpty else {
        print("devkat-push: cancelled"); exit(1)
    }

    print("Password: ", terminator: "")
    guard let password = readLine()?.trimmingCharacters(in: .whitespaces), !password.isEmpty else {
        print("devkat-push: cancelled"); exit(1)
    }

    do {
        let creds: StoredCredentials
        if password == "signup" {
            print("Creating account…")
            var newPassword = ""
            while newPassword.count < 8 {
                print("Choose a password (min 8 chars): ", terminator: "")
                newPassword = readLine()?.trimmingCharacters(in: .whitespaces) ?? ""
            }
            creds = try signUp(email: email, password: newPassword)
            print("devkat-push: ✓ account created and logged in as \(email)")
        } else {
            creds = try signIn(email: email, password: password)
            print("devkat-push: ✓ logged in as \(email)")
        }
        try saveCredentials(creds)
    } catch {
        print("devkat-push: login failed – \(error.localizedDescription)")
        exit(1)
    }
}

func runLogout() {
    clearCredentials()
    print("devkat-push: logged out")
}

// MARK: - List

func listSessions() {
    let files = findAllSessionFiles(in: claudeDir)
        .sorted {
            let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return a > b
        }

    if files.isEmpty { print("No session files found."); return }
    print("\(files.count) sessions (newest first):")
    for (i, f) in files.prefix(20).enumerated() {
        let mod = (try? f.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        let dateStr = mod.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .short) } ?? "?"
        print("  \(i + 1). \(f.lastPathComponent)  [\(dateStr)]  \(f.deletingLastPathComponent().lastPathComponent)")
    }
}

// MARK: - Helpers

func printSummary(_ s: ParsedSession) {
    let df = DateFormatter(); df.dateFormat = "HH:mm"
    let dur = formatDuration(s.activeDuration)
    print("  ✓ \(s.repoAlias ?? "unknown")  \(df.string(from: s.startedAt))–\(df.string(from: s.endedAt))  \(dur)  +\(s.linesAdded)/-\(s.linesRemoved)  \(formatTokens(s.tokens)) tokens  [\(s.model)]")
}

func formatDuration(_ t: TimeInterval) -> String {
    let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
    return h == 0 ? "\(m)m" : "\(h)h\(String(format: "%02d", m))m"
}

func formatTokens(_ n: Int) -> String {
    if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
    if n >= 1_000     { return String(format: "%.1fk", Double(n) / 1_000) }
    return "\(n)"
}

run()
