# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build from command line
xcodebuild -scheme AIssistant -configuration Debug build

# Open in Xcode
open AIssistant.xcodeproj
```

Target: macOS 13.0+ (arm64/x86_64). Two targets: `AIssistant` (app) and `Internal` (framework).

Tests use Swift Testing (`@Test` macro, not XCTest). Run a single test file:
```bash
xcodebuild test -scheme AIssistant -only-testing:AIssistantTests/<TestClassName>/<testMethodName>
```

## Architecture

AIssistant is a macOS SwiftUI app for browsing and editing AI assistant platform config files (Claude Code `~/.claude/`, OpenAI Codex `~/.codex/`). It supports viewing/editing skills, agents, commands, MCP server configs, project configs, and a shared `~/CLAUDE.md`.

### Layer Structure

- **AIssistant/** — App target: SwiftUI views (`Views/`), view models (`ViewModels/`)
- **Internal/** — Framework: models (`Models/`), services (`Services/`), platform scanners (`Platforms/ClaudeCode/`, `Platforms/Codex/`)

### Data Flow

`AppViewModel` (`@Observable`) holds app state. Sidebar selection (platform + category) triggers async scanning via platform-specific scanners. Scanned items populate the content list. File system changes are detected by `DirectoryWatcher` (dispatch source–based, 300ms debounce) and trigger rescans via a `refreshID` UUID pattern that invalidates SwiftUI `.task` observers.

### Key Types

- `PlatformKind` — Enum: `.claudeCode`, `.codex`; has `cloudPrefix` and `scanner(for:)` factory
- `ContentCategoryKind` — Enum: `.skills`, `.agents`, `.commands`, `.mcpServers`, `.projectConfigs`, `.sharedClaudeMD`
- `ContentItem` — Main data model with parsed `FrontmatterDocument`; extended via `ContentItem+Cloud.swift`, `ContentItem+SharedClaudeMD.swift`
- `PlatformScanner` — Protocol with async `scan()` and optional `watchedDirectories`; implemented by `ClaudeCodeScanner` and `CodexScanner`
- `FrontmatterParser` — Custom (non-strict) YAML-like `---` block parser; supports block scalars (`|`/`>`), indented continuations, multiple field-name conventions
- `TransferService` — Copies items between platforms; maps field names (e.g. Claude's `description` ↔ Codex's `short_description`)

### Cloud Sync

`CloudSyncService` (`@MainActor` singleton) syncs items to iCloud via **SyncEngine** + SwiftData (`CachedCloudFile` model). Container: `iCloud.com.standalone.aissistant`. `CloudStatusCache` polls sync state for UI badges (`.notBacked`, `.synced`, `.pending`). Cloud record names are hierarchical: `Platform/relative/path/to/file.md`.

### Command Activation

Commands can be activated/deactivated (moved in/out of `~/.claude/commands/`). The original path is stored as an extended attribute (`com.aissistant.originalPath`) on the file so deactivation can restore it to its source location.

### UI Structure

Three-pane `NavigationSplitView`: Sidebar (platform picker + category list + recents) | Content list (scanned items with live reload) | Detail (`HSplitView` with NSTextView-based markdown editor + MarkdownUI preview, metadata grid).

Detail view auto-saves with a 500ms debounced `Task`. Content list uses a local `LoadingState<[ContentItem]>` enum (`.idle`, `.loading`, `.empty`, `.failed`, `.loaded`).

## Conventions

- Use SwiftUI only, no UIKit fallbacks (NSTextView integration via `NSViewRepresentable` is acceptable for the editor)
- Avoid hard-coded dimensions in layout code
- Keep `.swift` files around 100 lines; split large types into functionality-based files
- Use `@Observable` macro for state management (not `ObservableObject`)
- Persist user preferences via **SharedSettings** (not `UserDefaults` directly)
- Run `afplay /System/Library/Sounds/Glass.aiff` when tasks complete

## Dependencies (SPM)

- **MarkdownUI** — Markdown rendering in preview pane
- **SyncEngine** — CloudKit sync (from `bengottlieb/SyncEngine`)
- **Suite**, **Journalist**, **Achtung**, **CrossPlatformKit**, **Convey**, **SharedSettings**, **JohnnyCache**, **Chronicle**, **Beholder**, **TagAlong** — mostly from `ios-tooling` GitHub org
