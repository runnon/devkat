<wizard-report>
# PostHog post-wizard report

The wizard completed a deep integration of the Devkat iOS app. PostHog was already partially integrated; the wizard filled in the remaining gaps and built a dashboard to track key product metrics.

**Changes made in this run:**

- `DEVKAT/Views/HomeView.swift` — Added `cli_update_command_copied` capture (with `version` property) inside `CLIUpdateSheet`, where only an OSLog entry existed before.
- `DEVKAT/Views/CopyView.swift` — Added `weekly_totals_copied` and `weekly_totals_saved` captures inside `WeeklyTripleTile`, which had no tracking.
- `.env` — Confirmed and updated `POSTHOG_PROJECT_TOKEN` and `POSTHOG_HOST` values.

**Existing integration (already in place):**

- PostHog SDK via SPM (`posthog-ios` v3.58.1, latest), `captureApplicationLifecycleEvents = true`.
- `PostHogEnv` enum reads keys from Xcode scheme Run environment variables — no hardcoded secrets.
- User identification on sign-in/sign-up (`AuthView.swift`), `reset()` on sign-out and account deletion (`SettingsView.swift`).

## Event inventory

| Event | Description | File |
|---|---|---|
| `sign_up_submitted` | User submits the sign-up form | `AuthView.swift` |
| `sign_in_submitted` | User submits the sign-in form | `AuthView.swift` |
| `sign_up_failed` | Sign-up attempt failed (with error) | `AuthView.swift` |
| `sign_in_failed` | Sign-in attempt failed (with error) | `AuthView.swift` |
| `session_tapped` | User taps a session card (with sources, duration, tokens) | `RootView.swift` |
| `overlay_copied` | User copies an overlay tile (with `tile` property) | `CopyView.swift` |
| `overlay_saved` | User saves an overlay tile to Photos (with `tile` property) | `CopyView.swift` |
| `weekly_totals_copied` | User copies the weekly totals overlay | `CopyView.swift` |
| `weekly_totals_saved` | User saves the weekly totals overlay | `CopyView.swift` |
| `cli_install_command_copied` | User copies the CLI install curl command | `HomeView.swift` |
| `cli_update_command_copied` | User copies the CLI update curl command (with `version`) | `HomeView.swift` |
| `cli_update_prompt_dismissed` | User dismisses the CLI update prompt (with `version`) | `HomeView.swift` |
| `review_prompt_positive` | User responds positively to the in-app review prompt | `RootView.swift` |
| `review_prompt_negative` | User responds negatively to the in-app review prompt | `RootView.swift` |
| `review_feedback_submitted` | User submits written negative feedback (with `char_count`) | `RootView.swift` |
| `signed_out` | User signs out | `SettingsView.swift` |
| `account_deleted` | User deletes their account | `SettingsView.swift` |

## Next steps

We've built a dashboard and insights to monitor user behavior based on the instrumented events:

- [Analytics basics dashboard](/dashboard/1565574)
- [Sign-up to Overlay Copy Funnel](/insights/UeIuHevy) — conversion from auth attempt to copying an overlay
- [Daily Active Users](/insights/v9rbV7zr) — unique users tapping sessions per day
- [Overlay Copies by Tile Type](/insights/fQKcFlSS) — which overlay tiles users copy most
- [Auth Attempts: Sign-up vs Sign-in](/insights/3nKA6jN6) — daily sign-up vs sign-in submission trend
- [Review Prompt Sentiment](/insights/G1angdgC) — weekly positive vs negative review prompt responses

### Agent skill

We've left an agent skill folder in your project at `.claude/skills/integration-swift/`. You can use this context for further agent development when using Claude Code. This will help ensure the model provides the most up-to-date approaches for integrating PostHog.

</wizard-report>
