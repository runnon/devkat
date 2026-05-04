import XCTest
import Foundation
@testable import DevKatParser

final class DevKatParserTests: XCTestCase {

    func testFindSessions() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let claudeDir = home.appendingPathComponent(".claude")
        guard FileManager.default.fileExists(atPath: claudeDir.path) else {
            throw XCTSkip("No ~/.claude directory on this machine")
        }

        let files = findAllSessionFiles(in: claudeDir)
        XCTAssertFalse(files.isEmpty, "Expected at least one session file")
        print("Found \(files.count) session file(s)")
    }

    func testParseLatestSession() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let claudeDir = home.appendingPathComponent(".claude")
        guard FileManager.default.fileExists(atPath: claudeDir.path) else {
            throw XCTSkip("No ~/.claude directory on this machine")
        }

        guard let latest = findLatestSessionFile(in: claudeDir) else {
            throw XCTSkip("No session files found")
        }

        let session = try parseSession(at: latest)
        print("Parsed session:")
        print("  id: \(session.id)")
        print("  model: \(session.model)")
        print("  startedAt: \(session.startedAt)")
        print("  endedAt: \(session.endedAt)")
        print("  activeDuration: \(session.activeDuration)s")
        print("  linesAdded: \(session.linesAdded)")
        print("  linesRemoved: \(session.linesRemoved)")
        print("  filesTouched: \(session.filesTouched)")
        print("  tokens: \(session.tokens)")
        print("  repoAlias: \(session.repoAlias ?? "nil")")
        print("  gitBranch: \(session.gitBranch ?? "nil")")

        XCTAssertFalse(session.id.isEmpty)
        XCTAssertLessThanOrEqual(session.startedAt, session.endedAt)
        XCTAssertGreaterThanOrEqual(session.activeDuration, 0)
    }
}
