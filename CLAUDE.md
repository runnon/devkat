# CLAUDE.md

Project conventions and rules for AI assistants working on this codebase.

## Supabase Migrations

- **Never edit an already-applied migration.** Once a migration has been pushed to the remote database, it is immutable. To fix or change behavior, create a new migration file with the corrective SQL (e.g., `CREATE OR REPLACE FUNCTION`, `ALTER TABLE`, etc.).
- Migration filenames use the format `YYYYMMDDHHMMSS_description.sql`.
- Run `supabase db push` to apply new migrations to the linked remote project.

## Releasing devkat-push

The CLI binary (`devkat-push`) is distributed via GitHub Releases on **this repo** (`runnon/devkat`). Users install it with:

```
curl -fsSL https://raw.githubusercontent.com/runnon/devkat/main/scripts/install.sh | sh
```

**When to release:** after any commit to `devkat-cli/` that changes user-facing behavior (bug fixes, new features, parser changes). No need to release for iOS-only or infra-only changes.

**How to release:**

```bash
git tag v0.X.Y && git push origin v0.X.Y
```

The GitHub Actions workflow (`.github/workflows/release.yml`) handles the rest — builds on macOS, packages the binary, and creates the release. It uses the built-in `GITHUB_TOKEN` (no PAT needed).

**Version format:** semver-ish `v0.MINOR.PATCH`. Bump patch for fixes, minor for new features.

**CLI version tracking:** `devkat-cli/Sources/devkat-push/main.swift` intentionally uses `DEVKAT_CLI_VERSION_PLACEHOLDER`. Do not manually edit it for releases. The GitHub Actions release workflow injects the pushed tag without the leading `v` before building, so a `v0.4.0` tag produces a binary that reports `0.4.0` to Supabase.

## Security & secrets

- Never commit `.env`, credentials, private keys, or tokens. `.gitignore` blocks them, and the `gitleaks` CI workflow (`.github/workflows/gitleaks.yml`) scans every PR.
- The Supabase **publishable** key (`sb_publishable_...`) is intentionally embedded in client code (iOS app, web app). RLS protects user data — every user-facing table has policies that key on `auth.uid() = user_id`. Never put the Supabase **secret** key in client code.
- PostHog project tokens (`phc_...`) used in the iOS app are loaded from the Xcode scheme environment, not hardcoded.
