# CLAUDE.md

Project conventions and rules for AI assistants working on this codebase.

## Supabase Migrations

- **Never edit an already-applied migration.** Once a migration has been pushed to the remote database, it is immutable. To fix or change behavior, create a new migration file with the corrective SQL (e.g., `CREATE OR REPLACE FUNCTION`, `ALTER TABLE`, etc.).
- Migration filenames use the format `YYYYMMDDHHMMSS_description.sql`.
- Run `supabase db push` to apply new migrations to the linked remote project.

## Releasing devkat-push

The CLI binary (`devkat-push`) is distributed via GitHub Releases on `runnon/devkat-releases`. Users install it with `curl -fsSL https://raw.githubusercontent.com/runnon/devkat-releases/main/install.sh | sh`.

**When to release:** after any commit to `devkat-cli/` that changes user-facing behavior (bug fixes, new features, parser changes). No need to release for iOS-only or infra-only changes.

**How to release:**

```bash
git tag v0.X.Y && git push origin v0.X.Y
```

The GitHub Actions workflow (`.github/workflows/release.yml`) handles the rest — builds on macOS, packages the binary, and creates the release on `runnon/devkat-releases`.

**Version format:** semver-ish `v0.MINOR.PATCH`. Bump patch for fixes, minor for new features. Current: v0.3.6.
