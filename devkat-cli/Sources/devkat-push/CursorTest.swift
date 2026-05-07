import Foundation
import DevKatParser

/// Diagnostic: enumerates Cursor composers and reports which would be pushed
/// vs skipped, then attributes API tokens to each post-cutoff session segment.
/// Read-only — does not write to Supabase or sync state.
func runCursorTest() {
    let cutoff = loadInstallTimestamp()
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm"
    df.timeZone = TimeZone(identifier: "UTC")

    print("─── cursor cutoff test ───")
    print("install cutoff: \(df.string(from: cutoff)) UTC")
    print()

    // Only post-cutoff composers should ever be returned.
    let postCutoffRows = findAllCursorSessions(since: cutoff)
    print("composers post-cutoff: \(postCutoffRows.count)")
    for row in postCutoffRows {
        let updated = Date(timeIntervalSince1970: Double(row.updatedAtMs) / 1000.0)
        print("  ✓ \(row.composerId.prefix(8))  updated=\(df.string(from: updated))  +\(row.linesAdded)/-\(row.linesRemoved)")
    }
    print()

    // Sanity-check the parser is actually filtering: the unfiltered scan
    // returns *every* eligible composer regardless of date.
    let allRows = findAllCursorSessions(since: Date(timeIntervalSince1970: 0))
    let preCutoff = allRows.filter { $0.updatedAtMs < Int64(cutoff.timeIntervalSince1970 * 1000) }
    print("composers pre-cutoff (should be skipped): \(preCutoff.count)")
    let leaks = postCutoffRows.filter { $0.updatedAtMs < Int64(cutoff.timeIntervalSince1970 * 1000) }
    if leaks.isEmpty {
        print("  ✓ no pre-cutoff composer leaked into the post-cutoff scan")
    } else {
        print("  ✗ LEAK: \(leaks.count) pre-cutoff composers in post-cutoff scan")
        for row in leaks { print("    - \(row.composerId)") }
    }
    print()

    // Live API attribution sanity check.
    let apiEvents = fetchCursorUsageEvents(since: cutoff)
    print("API usage events fetched since cutoff: \(apiEvents.count)")
    let apiBurnTotal = apiEvents.reduce(0) { $0 + $1.burnTokens }
    print("API total burn tokens: \(apiBurnTotal)")

    let assigned = attributeCursorEvents(apiEvents, to: postCutoffRows)
    let assignedCount = assigned.values.reduce(0) { $0 + $1.count }
    print("attributed events: \(assignedCount) / \(apiEvents.count)")
    print()

    print("per-session token attribution:")
    var attributed = 0
    for row in postCutoffRows {
        let composerEvents = assigned[row.composerId] ?? []
        let parsed = parseCursorSessions(row, apiEvents: composerEvents, cutoff: cutoff)
        for s in parsed {
            // Confirm no segment leaks pre-cutoff bubbles
            let preCutoffWarning = s.startedAt < cutoff ? "  ⚠ STARTS BEFORE CUTOFF" : ""
            attributed += s.tokens
            print("  \(row.composerId.prefix(8))  \(df.string(from: s.startedAt)) → \(df.string(from: s.endedAt))  tokens=\(s.tokens)  +\(s.linesAdded)/-\(s.linesRemoved)\(preCutoffWarning)")
        }
    }
    print()
    print("attributed: \(attributed) tokens (sanity: should be ≤ API total \(apiBurnTotal))")
    if attributed > apiBurnTotal {
        print("  ✗ DOUBLE-COUNTING: attributed > API total")
    } else {
        print("  ✓ no double-counting")
    }
}
