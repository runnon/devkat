# DEVKAT — Planning

## 1. Product

An iOS app that turns a developer's AI coding sessions into beautiful, shareable cards. Inspired by **Share Aura** (Aura Movement Technology, founded by Zach Pogrob, launched Aug 2025) — the running app that turned workout stats into Instagram-worthy overlays via opinionated templates and frictionless capture.

**v1 data source:** Claude Code session transcripts (`~/.claude/projects/*.jsonl`).
**Future sources:** Cursor, Codex/GitHub Copilot, Aider, etc.

**Why it can work:** developers already post about what they shipped on X, LinkedIn, Discord. Today they screenshot terminals or paste markdown. There is no opinionated, designed artifact for an AI coding session the way Strava + Share Aura created one for a run.

## 2. Session card — stats spec (locked)

Each session renders five stats. Label = concept; value = number with unit inline.

| Label        | Value                  |
|--------------|------------------------|
| **Duration** | `2h 14m`               |
| **Volume**   | `+842 / −137 lines`    |
| **Pace**     | `437 lines/hr`         |
| **Scope**    | `12 files`             |
| **Burn**     | `18.4k tokens`         |

Reference card layout:

```
DURATION    VOLUME              PACE
2h 14m      +842 / −137 lines   437 lines/hr

SCOPE              BURN
12 files           18.4k tokens
```

### How each stat is derived from the JSONL

A session = one `~/.claude/projects/<slug>/<session-uuid>.jsonl` file. Each line is a JSON event with `type`, `timestamp`, `message`, etc.

| Stat         | Computation                                                                                                                      |
|--------------|----------------------------------------------------------------------------------------------------------------------------------|
| **Duration** | `max(timestamp) − min(timestamp)`. Subtract idle gaps >15 min between consecutive events to get "active" duration.               |
| **Volume**   | Sum lines added/removed across all `Edit` / `Write` / `MultiEdit` tool_results — parse the diff snippet returned in each result. |
| **Pace**     | Total lines changed (added + removed, or just added — pick one) ÷ active duration in hours.                                      |
| **Scope**    | Count of unique file paths across all `Edit` / `Write` / `Read` tool_use blocks.                                                 |
| **Burn**     | Sum `message.usage.input_tokens + output_tokens + cache_creation + cache_read` across every assistant line.                      |

### Secondary stats (deeper view, post-v1)

- **Prompts** — count of `type == "user"` AND `userType == "external"` AND content is text (not a tool_result) AND `isSidechain != true`. The cadence/interaction count.
- **Tool calls** — total count of `tool_use` blocks (intensity proxy).
- **Model** — from `message.model` on assistant lines.
- **Repo / branch** — from `cwd` and `gitBranch` (aliased by default).
- **Cost ($)** — derived from tokens × model price.

## 3. iOS app — UX

**No auth in the mobile app.** Data arrives silently via the user's own Apple ID (CloudKit).

### Why DEVKAT renders the composed image itself

Twitter, LinkedIn, and several other apps make in-app image editing painful or impossible — pasted images can't be cropped, layered, or annotated reliably. DEVKAT therefore does the **photo + stat overlay composition in-app** and outputs a single finished image. The user never has to edit anything in the destination app — they just paste or upload.

This mirrors Share Aura's flow: pick activity → pick background → pick overlay preset → copy/save the composed image.

### Screen 1 — Home (activities)

```
┌─────────────────────────────────┐
│ DEVKAT                       +  │
├─────────────────────────────────┤
│ Today                           │
│ ┌─────────┐  ┌─────────┐        │
│ │ Today   │  │ Today   │        │
│ │ 2h 14m  │  │ 47m     │        │
│ │ +842/-137│  │ +120/-12│        │
│ │ 12 files│  │ 3 files │        │
│ └─────────┘  └─────────┘        │
│                                 │
│ Yesterday                       │
│ ┌─────────┐  ┌─────────┐        │
│ │Yesterday│  │Yesterday│        │
│ │ 1h 02m  │  │ 3h 18m  │        │
│ └─────────┘  └─────────┘        │
└─────────────────────────────────┘
```

- **Title:** `DEVKAT` (top-left).
- **Plus button:** top-right. Manual import — file picker / share-sheet handler that accepts a `.jsonl` (e.g. AirDropped from Mac, picked from Files).
- **Body:** sessions grouped by day, **two cards per row**, most recent day first.
- **Card content:** stats-only — no photo background. Shows the date label (`Today` / `Yesterday` / `May 2`) plus the five stats from §2 in a compact layout.
- **Tap a card →** Screen 2 (background picker).

### Screen 2 — Pick background

After tapping an activity, the user chooses a photo from their camera roll to use as the background image.

```
┌─────────────────────────────────┐
│ ‹  Pick a background            │
├─────────────────────────────────┤
│ Camera Roll  Stock              │
├─────────────────────────────────┤
│ ┌────┐ ┌────┐ ┌────┐            │
│ │ph 1│ │ph 2│ │ph 3│            │
│ └────┘ └────┘ └────┘            │
│ ┌────┐ ┌────┐ ┌────┐            │
│ │ph 4│ │ph 5│ │ph 6│            │
│ └────┘ └────┘ └────┘            │
└─────────────────────────────────┘
```

- **Camera Roll tab:** uses `PHPicker`. v1 supports still photos; videos can come later.
- **Stock tab (post-v1):** built-in backgrounds for users who don't want to use a personal photo (gradients, code-themed abstracts, terminal screenshots, etc.).
- **Tap a photo →** Screen 3 (preset picker).

### Screen 3 — Pick preset (overlay + composition)

The chosen photo is shown with **every preset overlay applied**, so the user can see the final composed image in each style and pick the one that fits. Tapping a preset's **Copy** button copies that finished image to the iOS clipboard.

```
┌─────────────────────────────────┐
│ ‹  Pick a preset                │
├─────────────────────────────────┤
│ ┌──────────┐  ┌──────────┐      │
│ │photo +   │  │photo +   │      │
│ │ overlay 1│  │ overlay 2│      │
│ │  [Copy]  │  │  [Copy]  │      │
│ └──────────┘  └──────────┘      │
│ ┌──────────┐  ┌──────────┐      │
│ │photo +   │  │photo +   │      │
│ │ overlay 3│  │ overlay 4│      │
│ │  [Copy]  │  │  [Copy]  │      │
│ └──────────┘  └──────────┘      │
└─────────────────────────────────┘
```

- Each tile is a **live render** of the user's photo + that preset's stat overlay — what they get is what they see.
- **Presets vary by:**
  - Which stats are shown (e.g., minimal: Duration + Pace; full: all five from §2).
  - Typography (serif editorial / mono terminal / sans modern).
  - Layout (corner stack / centered hero / footer strip / full-width header).
  - Color treatment (dark scrim / light scrim / no scrim / accent bar).
- **Copy action:** renders the composed image to a `UIImage`, places it on `UIPasteboard.general` as `image/png`. User pastes into Instagram, X, LinkedIn, Discord, Slack, etc.
- **Secondary actions per preset (post-v1):** Save to camera roll, Share sheet.
- **Aspect ratios:** ship with 9:16 (Stories) and 1:1 (X/LinkedIn) at minimum. 16:9 later.
- **Aesthetic direction for v1 overlays:** dark-mode-first, monospace + soft gradients (Vercel / Linear / Raycast feel). Avoid GitHub-green / contribution-graph look.

### Composition — implementation note

The composed image is rendered using `ImageRenderer` (SwiftUI) over a SwiftUI view that stacks: `Image(background)` → optional scrim → preset's stat layout. This gives us full control over typography and layout, and lets the same SwiftUI view drive both the on-screen preview and the exported `UIImage` — no separate render pipeline.

## 4. Architecture

### v0 — manual import only (ship first)

- **iOS app only.** No backend, no Mac companion.
- User AirDrops or Files-picks a `.jsonl` from their Mac via the **+** button.
- Parser runs on-device; session is added to the grid.
- Lets us validate templates, layout, and the design screen without writing any Mac code.

### v1 — automatic capture via Mac companion + CloudKit

- **Mac menu-bar companion app**, signed and notarized.
  - On first run, installs a `SessionEnd` hook in `~/.claude/settings.json`. The hook fires when a `claude` session ends and receives `session_id`, `transcript_path`, `cwd` on stdin.
  - Also runs an FSEvents watcher on `~/.claude/projects/` as a fallback.
  - Parses the JSONL, computes the session record, writes a `CKRecord` to the user's **CloudKit private database**.
- **iOS app** subscribes (`CKQuerySubscription`) to that private database. New session → APNs push → grid updates.
- **No login screen ever.** Same Apple ID on Mac and iOS = same data. Apple handles auth invisibly.

### Why CloudKit (not our own backend)

- No servers to run.
- Per-user data isolation is automatic.
- Push notifications come for free.
- Privacy story is straightforward: data lives in the user's iCloud, not ours.

### Alternative considered: iCloud Drive ubiquity container

Simpler than CloudKit but no push, slower sync, file-based not record-based. Use only if CloudKit proves heavy.

## 5. Session record schema (Swift)

```swift
struct Session: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let activeDuration: TimeInterval   // duration minus idle gaps
    let linesAdded: Int
    let linesRemoved: Int
    let patches: Int                   // # Edit/Write/MultiEdit calls
    let filesTouched: Int              // unique file paths
    let tokensIn: Int
    let tokensOut: Int
    let cacheRead: Int
    let cacheCreate: Int
    let cost: Decimal                  // tokens × model price
    let model: String
    let repoAlias: String?             // hashed/aliased by default
    let branch: String?
    let prompts: Int                   // for cadence
    let toolCalls: Int                 // for intensity
}
```

## 5b. Auth (post-v1)

v1 ships with no auth — data arrives via the user's own Apple ID through CloudKit.

When auth is added later, it must be **zero-form-entry**:

- **Sign in with Apple** (primary on iOS — required by App Store guidelines if any third-party social login is offered).
- **Sign in with Google** (secondary).
- No email/password, no username field, no profile setup.
- One tap → signed in.

Auth is only needed if/when we move beyond per-user CloudKit (e.g., public profiles, follower feeds, leaderboards, team accounts, web app). Until then, skip it.

## 6. Privacy

Code transcripts contain source code, file paths, env values echoed by Bash, and possibly secrets pasted into prompts. Treat as sensitive by default.

- **Default-private.** Cards are generated locally; nothing leaves the device until the user taps share.
- **Repo aliasing.** `acme-internal-trading-prod` → `client-app`. Repo names are like home addresses — don't expose them by default.
- **Filename redaction.** Show `src/auth/****.ts` unless the user explicitly opts in to real paths.
- **Pre-flight secret scan** on any code snippet that would appear in an overlay (regex for AWS keys, `ghp_`, `sk-`, `Bearer`, `.env` content).
- **Share preview** before export, highlighting what's redacted vs. visible.
- **Work mode toggle** that disables sharing entirely — for sessions touching employer code under NDA.

## 7. Build order

1. **JSONL parser as a Swift CLI.** Feed it a `.jsonl`, get back a `Session` JSON. Pure function; easiest piece to test.
2. **iOS app v0 — Home screen.** SwiftUI grid + share-sheet/file-picker import. Stats-only activity cards. No CloudKit, no Mac companion yet.
3. **iOS Background picker.** `PHPicker` for camera roll selection.
4. **iOS Preset picker + composition.** Build 3–4 presets as SwiftUI views, render with `ImageRenderer`, copy `UIImage` to `UIPasteboard`.
5. **Mac menu-bar companion v1.** Wraps the parser, installs the hook, writes to CloudKit.
6. **iOS CloudKit read path.** `CKQuerySubscription`, automatic grid updates.

## 8. Open questions / TBD

- **Pace numerator** — additions only, or additions + removals? (A 0/1000 cleanup session would have pace = 0 under additions-only.)
- **Idle gap threshold** — 15 min is a guess; calibrate against real sessions.
- **Template aesthetic** — needs a design pass. Reference: Vercel, Linear, Raycast, Arc.
- **Aspect ratios** — start with 9:16 (Stories) and 1:1 (X/LinkedIn). 16:9 later.
- **Cross-platform capture** — Mac-only for v1. Linux/Windows companions later. iPad Claude Code is also a future blind spot.
- **Cost model display** — show `$0.42` or `18.4k tokens`? Currently the latter (label = `Burn`).
- **Multi-source future** — schema and architecture should accommodate Cursor, Aider, etc. without a rewrite.
