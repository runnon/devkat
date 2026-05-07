import Foundation

struct LeaderboardEntry: Codable, Identifiable {
    let email: String
    let total_tokens: Int

    var id: String { email }

    var displayName: String {
        email.components(separatedBy: "@").first ?? email
    }

    var formattedTokens: String {
        if total_tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(total_tokens) / 1_000_000)
        } else if total_tokens >= 1_000 {
            return String(format: "%.1fK", Double(total_tokens) / 1_000)
        }
        return "\(total_tokens)"
    }
}
