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

No tests exist yet. When adding tests, use Swift Testing framework.

## Architecture

AIssistant is a macOS SwiftUI app for browsing and editing AI assistant platform config files (Claude Code `~/.claude/`, OpenAI Codex `~/.codex/`). It supports viewing/editing skills, agents, commands, MCP server configs, and project configs.

### Layer Structure

- **AIssistant/** — App target with SwiftUI views and view models
- **Internal/** — Framework containing models, services, and platform scanners

### Data Flow

`AppViewModel` (`@Observable`) holds app state. Sidebar selection (platform + category) triggers async scanning via platform-specific scanners. Scanned items populate the content list. Selecting an item shows metadata + dual-pane editor/preview in the detail view.

### Key Types

- `PlatformKind` — Enum: `.claudeCode`, `.codex`
- `ContentCategoryKind` — Enum: `.skills`, `.agents`, `.commands`, `.mcpServers`, `.projectConfigs`
- `ContentItem` — Main data model with parsed `FrontmatterDocument`
- `PlatformScanner` — Protocol implemented by `ClaudeCodeScanner` and `CodexScanner`
- `FrontmatterParser` — Extracts YAML-like `---` frontmatter blocks from markdown
- `TransferService` — Copies items between platforms with field mapping

### UI Structure

Three-pane `NavigationSplitView`: Sidebar (platform picker + category list) | Content list (scanned items) | Detail (`HSplitView` with markdown editor + preview, metadata grid).

## Conventions

- Use SwiftUI only, no UIKit fallbacks
- Avoid hard-coded dimensions in layout code
- Keep `.swift` files around 100 lines; split large types into functionality-based files
- Use `@Observable` macro for state management (not `ObservableObject`)
- Run `afplay /System/Library/Sounds/Glass.aiff` when tasks complete

## Dependencies (SPM)

Key packages: **MarkdownUI** (markdown rendering), **Suite**, **Journalist** (logging), **Achtung**, **CrossPlatformKit**, **Convey** — mostly from `ios-tooling` GitHub org.
