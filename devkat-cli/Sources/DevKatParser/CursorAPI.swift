import Foundation
import SQLite3

// MARK: - Cursor server-side usage API
//
// Cursor stopped populating `tokenCount` in local bubble records around early 2026.
// This module pulls token usage straight from Cursor's backend so we can still
// attribute "tokens burned" to local Cursor sessions.
//
// Endpoint:  POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetFilteredUsageEvents
// Auth:      Bearer <accessToken>  (same JWT Cursor.app stores in state.vscdb)

public struct CursorUsageEvent {
    public let timestamp: Date
    public let model: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let cacheReadTokens: Int
    public let cacheWriteTokens: Int

    /// Tokens we count as "burned" — input + output. Cache reads are excluded
    /// (they're the cached portion). This matches the semantics the Claude
    /// and Codex parsers use.
    public var burnTokens: Int { inputTokens + outputTokens }
}

private let cursorAPIDBPath: String = {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    return "\(home)/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
}()

/// Reads Cursor's signed-in access token straight from the local state.vscdb.
/// Returns nil if Cursor isn't installed / signed in.
public func loadCursorAccessToken() -> String? {
    var db: OpaquePointer?
    guard sqlite3_open_v2(cursorAPIDBPath, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK else {
        return nil
    }
    defer { sqlite3_close(db) }
    sqlite3_busy_timeout(db, 5000)

    let sql = "SELECT value FROM ItemTable WHERE key = 'cursorAuth/accessToken'"
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
    defer { sqlite3_finalize(stmt) }

    guard sqlite3_step(stmt) == SQLITE_ROW, let blob = sqlite3_column_text(stmt, 0) else { return nil }
    var token = String(cString: blob)
    // The DB sometimes wraps the token in JSON-style quotes
    if token.hasPrefix("\""), token.hasSuffix("\""), token.count >= 2 {
        token = String(token.dropFirst().dropLast())
    }
    return token.isEmpty ? nil : token
}

/// Quick liveness check — JWT body has an `exp` claim in seconds.
public func cursorAccessTokenIsValid(_ token: String) -> Bool {
    let parts = token.split(separator: ".")
    guard parts.count == 3 else { return false }
    var b64 = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    while b64.count % 4 != 0 { b64.append("=") }
    guard let data = Data(base64Encoded: b64),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let exp = obj["exp"] as? Double
    else { return false }
    return exp > Date().timeIntervalSince1970
}

/// Fetches all usage events Cursor's API knows about within `[startDate, endDate]`.
/// Paginates synchronously (CLI context). Returns an empty array if auth or
/// the network fails — callers should fall back to local data.
public func fetchCursorUsageEvents(
    since startDate: Date,
    until endDate: Date = Date(),
    token: String? = nil,
    pageSize: Int = 100
) -> [CursorUsageEvent] {
    guard let token = token ?? loadCursorAccessToken(),
          cursorAccessTokenIsValid(token)
    else { return [] }

    let url = URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetFilteredUsageEvents")!
    let startMs = Int64(startDate.timeIntervalSince1970 * 1000)
    let endMs = Int64(endDate.timeIntervalSince1970 * 1000)

    var all: [CursorUsageEvent] = []
    var page = 1
    let maxPages = 200 // safety cap → 20k events

    while page <= maxPages {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        let body = "{\"startDate\":\"\(startMs)\",\"endDate\":\"\(endMs)\",\"page\":\(page),\"pageSize\":\(pageSize)}"
        req.httpBody = body.data(using: .utf8)

        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data?
        var status: Int = 0
        URLSession.shared.dataTask(with: req) { data, response, _ in
            responseData = data
            if let http = response as? HTTPURLResponse { status = http.statusCode }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .now() + 20)

        guard status == 200, let data = responseData,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let events = obj["usageEventsDisplay"] as? [[String: Any]]
        else { break }

        let total = (obj["totalUsageEventsCount"] as? Int) ?? all.count + events.count

        for e in events {
            guard let tsStr = e["timestamp"] as? String, let ms = Int64(tsStr) else { continue }
            let ts = Date(timeIntervalSince1970: Double(ms) / 1000.0)
            let model = (e["model"] as? String) ?? ""
            let tu = (e["tokenUsage"] as? [String: Any]) ?? [:]
            all.append(CursorUsageEvent(
                timestamp: ts,
                model: model,
                inputTokens: (tu["inputTokens"] as? Int) ?? 0,
                outputTokens: (tu["outputTokens"] as? Int) ?? 0,
                cacheReadTokens: (tu["cacheReadTokens"] as? Int) ?? 0,
                cacheWriteTokens: (tu["cacheWriteTokens"] as? Int) ?? 0
            ))
        }

        if events.count < pageSize || all.count >= total { break }
        page += 1
    }

    return all
}
