import Foundation
import Observation
import UIKit

@Observable
final class AppModel {
    var selectedSession: Session?
    var sessions: [Session] = []
    var installations: [Installation] = []
    var leaderboard: [LeaderboardEntry] = []
    var isLoggedIn: Bool = AuthTokens.stored != nil
    var isLoadingSessions = false

    init() {
        if isLoggedIn { Task { await fetchSessions() } }
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.isLoggedIn else { return }
            Task { await self.fetchSessions() }
        }
    }

    // MARK: - Auth

    func didSignIn() {
        isLoggedIn = true
        Task { await fetchSessions() }
    }

    func signOut() {
        AuthTokens.clear()
        isLoggedIn = false
        sessions = []
        installations = []
        selectedSession = nil
    }

    @MainActor
    func deleteAccount() async throws {
        guard let tokens = AuthTokens.stored else { throw SupabaseError.notLoggedIn }

        do {
            try await SupabaseService.shared.deleteCurrentUser(token: tokens.accessToken)
        } catch SupabaseError.http(401, _) {
            let refreshed = try await SupabaseService.shared.refreshTokens(tokens.refreshToken)
            refreshed.persist()
            try await SupabaseService.shared.deleteCurrentUser(token: refreshed.accessToken)
        }

        signOut()
    }

    // MARK: - Fetch

    @MainActor
    func fetchSessions() async {
        guard let tokens = AuthTokens.stored else { return }
        isLoadingSessions = true
        defer { isLoadingSessions = false }

        do {
            do {
                try await loadAll(token: tokens.accessToken)
            } catch SupabaseError.http(401, _) {
                let refreshed = try await SupabaseService.shared.refreshTokens(tokens.refreshToken)
                refreshed.persist()
                try await loadAll(token: refreshed.accessToken)
            }
        } catch {
            // Keep whatever we have; don't blank the screen on transient errors
            print("AppModel: fetchSessions error – \(error)")
        }
    }

    @MainActor
    private func loadAll(token: String) async throws {
        async let s = SupabaseService.shared.fetchSessions(token: token)
        async let i = SupabaseService.shared.fetchInstallations(token: token)
        let (sList, iList) = try await (s, i)
        sessions = sList
        installations = iList

        // Leaderboard is optional — don't block sessions on it.
        do {
            leaderboard = try await SupabaseService.shared.fetchLeaderboard(token: token)
        } catch {
            print("AppModel: leaderboard unavailable – \(error)")
            leaderboard = []
        }
    }
}
