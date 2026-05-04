# CLAUDE.md

Project conventions and rules for AI assistants working on this codebase.

## Supabase Migrations

- **Never edit an already-applied migration.** Once a migration has been pushed to the remote database, it is immutable. To fix or change behavior, create a new migration file with the corrective SQL (e.g., `CREATE OR REPLACE FUNCTION`, `ALTER TABLE`, etc.).
- Migration filenames use the format `YYYYMMDDHHMMSS_description.sql`.
- Run `supabase db push` to apply new migrations to the linked remote project.
