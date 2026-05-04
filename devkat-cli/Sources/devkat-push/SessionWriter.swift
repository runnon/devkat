import Foundation
import DevKatParser

// RPC params for merge_session — snake_case to match Postgres function args
private struct MergeParams: Encodable {
    let p_id: String
    let p_started_at: String
    let p_ended_at: String
    let p_active_duration: Double
    let p_lines_added: Int
    let p_lines_removed: Int
    let p_files_touched: Int
    let p_tokens: Int
    let p_model: String
    let p_repo_alias: String?
    let p_git_branch: String?
    let p_source: String
}

public func writeSession(_ session: ParsedSession) throws {
    let token = try validAccessToken()

    let fmt = ISO8601DateFormatter()
    let params = MergeParams(
        p_id: session.id,
        p_started_at: fmt.string(from: session.startedAt),
        p_ended_at: fmt.string(from: session.endedAt),
        p_active_duration: session.activeDuration,
        p_lines_added: session.linesAdded,
        p_lines_removed: session.linesRemoved,
        p_files_touched: session.filesTouched,
        p_tokens: session.tokens,
        p_model: session.model,
        p_repo_alias: session.repoAlias,
        p_git_branch: session.gitBranch,
        p_source: session.source.rawValue
    )

    let url = URL(string: "\(supabaseURL)/rest/v1/rpc/merge_session")!
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let encoder = JSONEncoder()
    req.httpBody = try encoder.encode(params)

    let sem = DispatchSemaphore(value: 0)
    var writeError: Error?

    URLSession.shared.dataTask(with: req) { data, response, error in
        defer { sem.signal() }
        if let error { writeError = error; return }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            writeError = AuthError(message: "HTTP \(http.statusCode): \(body)")
        }
    }.resume()

    sem.wait()

    if let writeError { throw writeError }
    print("devkat-push: → synced (\(session.source.rawValue) · \(session.id.prefix(8))…)")
}
