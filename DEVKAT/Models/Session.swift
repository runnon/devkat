import Foundation

struct Session: Identifiable, Hashable, Codable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let activeDuration: TimeInterval
    let linesAdded: Int
    let linesRemoved: Int
    let filesTouched: Int
    let tokens: Int
    let model: String
    let repoAlias: String?
    let gitBranch: String?

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt      = "started_at"
        case endedAt        = "ended_at"
        case activeDuration = "active_duration"
        case linesAdded     = "lines_added"
        case linesRemoved   = "lines_removed"
        case filesTouched   = "files_touched"
        case tokens
        case model
        case repoAlias      = "repo_alias"
        case gitBranch      = "git_branch"
    }

    var duration: TimeInterval { endedAt.timeIntervalSince(startedAt) }
    var linesTotal: Int { linesAdded + linesRemoved }
    var linesPerHour: Int {
        let hours = max(activeDuration / 3600, 0.0001)
        return Int(Double(linesTotal) / hours)
    }
}

// MARK: - Mock data (shown when not logged in / no sessions yet)

extension Session {
    static let mock: [Session] = {
        let cal = Calendar.current
        func at(_ daysAgo: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let base = cal.startOfDay(for: Date())
            let day  = cal.date(byAdding: .day, value: -daysAgo, to: base)!
            return cal.date(byAdding: .minute, value: hour * 60 + minute, to: day)!
        }

        return [
            Session(id: UUID(), startedAt: at(0, 9, 12), endedAt: at(0, 11, 26),
                    activeDuration: 2*3600+14*60, linesAdded: 842, linesRemoved: 137,
                    filesTouched: 12, tokens: 18_400, model: "Opus 4.7",
                    repoAlias: "client-app", gitBranch: "main"),
            Session(id: UUID(), startedAt: at(0, 14, 5), endedAt: at(0, 14, 52),
                    activeDuration: 47*60, linesAdded: 120, linesRemoved: 12,
                    filesTouched: 3, tokens: 6_200, model: "Sonnet 4.6",
                    repoAlias: "client-app", gitBranch: "feature/auth"),
            Session(id: UUID(), startedAt: at(1, 10, 30), endedAt: at(1, 11, 32),
                    activeDuration: 62*60, linesAdded: 214, linesRemoved: 88,
                    filesTouched: 5, tokens: 9_800, model: "Opus 4.7",
                    repoAlias: "infra", gitBranch: nil),
            Session(id: UUID(), startedAt: at(1, 15, 0), endedAt: at(1, 18, 18),
                    activeDuration: 3*3600+18*60, linesAdded: 1_204, linesRemoved: 432,
                    filesTouched: 21, tokens: 32_100, model: "Opus 4.7",
                    repoAlias: "client-app", gitBranch: "main"),
            Session(id: UUID(), startedAt: at(2, 8, 45), endedAt: at(2, 9, 30),
                    activeDuration: 45*60, linesAdded: 88, linesRemoved: 14,
                    filesTouched: 2, tokens: 5_400, model: "Sonnet 4.6",
                    repoAlias: "side-project", gitBranch: nil),
            Session(id: UUID(), startedAt: at(2, 13, 10), endedAt: at(2, 16, 2),
                    activeDuration: 2*3600+52*60, linesAdded: 612, linesRemoved: 240,
                    filesTouched: 9, tokens: 24_700, model: "Opus 4.7",
                    repoAlias: "side-project", gitBranch: "xav-dev"),
        ]
    }()
}

// MARK: - Formatting

enum SessionFormatting {
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h == 0 { return "\(m)m" }
        return "\(h)h \(String(format: "%02d", m))m"
    }

    static func tokens(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000     { return String(format: "%.1fk", Double(n) / 1_000) }
        return "\(n)"
    }

    static func dayLabel(for date: Date, today: Date = Date()) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f.string(from: date).uppercased()
    }
}
