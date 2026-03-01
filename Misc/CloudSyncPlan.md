# CloudKit Backup Support for AIssistant

## Context

The app manages AI platform config files (~/.claude/, ~/.codex/) but has no way to back them up. This adds CloudKit backup to a private database so users can preserve and restore any config file. The container is `iCloud.com.standalone.aissistant` with an `AIFile` record type.

## Architecture Decisions

- **Record names** derived from platform prefix + relative path (e.g. `"Claude/commands/foo.md"`, `"Codex/agents/openai.yaml"`)
- **Content stored as String field** on CKRecord (not CKAsset) -- config files are small text
- **Sync powered by CKSyncEngine** (Apple's SyncEngine framework) -- handles push/pull, conflict resolution, and change tracking automatically instead of manual CKDatabase calls
- **Local SwiftData database** acts as the cache/mirror of CloudKit state. A `CachedCloudFile` model stores record name, content, metadata, and sync status. This replaces the UserDefaults `Set<String>` approach and provides a queryable, persistent local store
- **Automatic local file updates** -- when CKSyncEngine delivers remote changes (via its delegate callbacks), the app writes updated content to the corresponding local config files, keeping the filesystem in sync with the server at all times
- **CloudKitService** lives in Internal framework, wrapping CKSyncEngine and its delegate
- **CloudStatusCache** lives in app target as `@Observable` class, backed by SwiftData queries, injected via `.environment()`

## Implementation Order

### Step 1: Xcode Project Configuration (manual)
- Add iCloud capability to AIssistant target with CloudKit checked
- Add container: `iCloud.com.standalone.aissistant`
- Xcode auto-generates entitlements file
- Create `AIFile` record type in CloudKit Dashboard with fields: `content` (String), `fileName` (String), `platform` (String), `category` (String), `lastModified` (Date/Time), `relativePath` (String)

### Step 2: Internal Framework -- SwiftData Model + Cloud Models (3 new files)

**`Internal/Models/CachedCloudFile.swift`** (~45 lines)
- SwiftData `@Model` class: recordName (unique), content, fileName, platform, category, lastModified, relativePath, syncStatus (enum: synced/pendingUpload/pendingDownload)
- Acts as the local mirror of CloudKit state, queryable for UI status indicators

**`Internal/Models/CloudRecord.swift`** (~35 lines)
- Codable/Sendable struct: recordName, content, fileName, platform, category, lastModified, relativePath
- Used as a lightweight transfer object between CKSyncEngine and SwiftData

**`Internal/Models/ContentItem+Cloud.swift`** (~35 lines)
- `PlatformKind.cloudPrefix` computed property ("Claude" / "Codex")
- `ContentItem.cloudRecordName` -- deterministic record name from platformKind.cloudPrefix + relative path within baseDirectory
- `ContentItem.cloudRelativePath` -- just the relative portion
- `ContentItem.toCloudRecord()` -- converts to CloudRecord for upload

### Step 3: Internal Framework -- SyncEngine Service (3 new files)

**`Internal/Services/CloudKitService.swift`** (~100 lines)
- Wraps `CKSyncEngine` -- initializes with the app's container and a `CKSyncEngine.Configuration`
- Conforms to `CKSyncEngineDelegate` to handle `handleEvent(_:)` callbacks
- `scheduleSend(_ item: ContentItem)` -- marks item as pending in SwiftData, adds to CKSyncEngine's send queue
- `delete(recordName:)` -- schedules deletion via CKSyncEngine
- Manages a `ModelContainer` for SwiftData access

**`Internal/Services/CloudKitService+SyncDelegate.swift`** (~80 lines)
- Handles `CKSyncEngine.Event` cases:
  - `.fetchedRecordZoneChanges` -- upserts into SwiftData `CachedCloudFile`, then writes the updated content to the local config file on disk (keeping local files in sync with server changes)
  - `.sentRecordZoneChanges` -- updates SwiftData sync status to `.synced`
  - `.fetchedDatabaseChanges` -- triggers zone-level fetch
  - `.willSendChanges` / `.didSendChanges` -- provides records from SwiftData pending queue
- Conflict resolution: server wins by default (latest server content overwrites local)

**`Internal/Services/CloudKitService+Restore.swift`** (~35 lines)
- `restoreToLocal(_ cachedFile: CachedCloudFile)` -- writes cached content to local file, returns URL
- `CloudKitServiceError` enum with localizedError conformance

### Step 4: App Target -- State (1 new file)

**`AIssistant/ViewModels/CloudStatusCache.swift`** (~55 lines)
- `@Observable` class backed by SwiftData queries against `CachedCloudFile`
- `isBackedUp(_ item:)` -- queries SwiftData for matching record name with `.synced` status
- `syncStatus(_ item:)` -- returns current sync state (synced/pending/not backed up)
- Holds a reference to the shared `ModelContainer` (injected at app startup alongside `CloudKitService`)

### Step 5: App Target -- Cloud UI (4 new files)

**`AIssistant/Views/Cloud/CloudIndicator.swift`** (~40 lines)
- Small cloud icon button (filled blue if backed up, outline if not)
- Tapping opens CloudSyncSheet

**`AIssistant/Views/Cloud/CloudSyncSheet.swift`** (~90 lines)
- Shows record name, upload button, and "Preview Changes" button (if already backed up)
- Fetches cloud record before opening preview
- Follows TransferSheet pattern (dismiss, error/success states)

**`AIssistant/Views/Cloud/CloudPreviewSheet.swift`** (~85 lines)
- HSplitView with local content (left) and cloud content (right)
- Monospaced text, scrollable, selectable
- "Replace Cloud with Local" and "Replace Local with Cloud" buttons
- Shows success/error inline

**`AIssistant/Views/Cloud/CloudToolbarButton.swift`** (~30 lines)
- Toolbar-sized button with label for DetailView toolbar

### Step 6: Modify Existing Views (3 files)

**`AIssistant/ContentView.swift`** -- Add `@State var cloudCache = CloudStatusCache()`, inject `.environment(cloudCache)`, add `.task { await cloudCache.refreshFromCloud() }`

**`AIssistant/Views/ContentList/ContentItemRow.swift`** -- Add `CloudIndicator(item:)` in an HStack next to the item name

**`AIssistant/Views/Detail/DetailView.swift`** -- Add `CloudToolbarButton(item:)` to toolbar

## Files Summary

| New File | Target | Purpose |
|----------|--------|---------|
| `Internal/Models/CachedCloudFile.swift` | Internal | SwiftData model for local CloudKit mirror |
| `Internal/Models/CloudRecord.swift` | Internal | Lightweight transfer object |
| `Internal/Models/ContentItem+Cloud.swift` | Internal | Record name computation |
| `Internal/Services/CloudKitService.swift` | Internal | CKSyncEngine wrapper + setup |
| `Internal/Services/CloudKitService+SyncDelegate.swift` | Internal | SyncEngine delegate -- handles remote changes, writes to local files |
| `Internal/Services/CloudKitService+Restore.swift` | Internal | Manual local file restore + errors |
| `AIssistant/ViewModels/CloudStatusCache.swift` | AIssistant | Observable cloud status cache (SwiftData-backed) |
| `AIssistant/Views/Cloud/CloudIndicator.swift` | AIssistant | Reusable cloud badge button |
| `AIssistant/Views/Cloud/CloudSyncSheet.swift` | AIssistant | Upload/sync options sheet |
| `AIssistant/Views/Cloud/CloudPreviewSheet.swift` | AIssistant | Side-by-side diff/confirm view |
| `AIssistant/Views/Cloud/CloudToolbarButton.swift` | AIssistant | Detail toolbar cloud button |

| Modified File | Changes |
|---------------|---------|
| `ContentView.swift` | CloudStatusCache creation + environment + refresh task |
| `ContentItemRow.swift` | CloudIndicator in row |
| `DetailView.swift` | CloudToolbarButton in toolbar |

## Verification
1. Build with `xcodebuild -scheme AIssistant -configuration Debug build`
2. Launch app, select a config file, click cloud button in toolbar or list row
3. Upload a file, verify cloud indicator turns blue/filled
4. Click indicator again, use "Preview Changes" to see side-by-side view
5. Test "Replace Cloud with Local" and "Replace Local with Cloud" flows
6. Quit and relaunch -- verify cloud indicators persist via SwiftData (no network needed for cached state)
7. Modify a file via CloudKit Dashboard or a second device -- verify CKSyncEngine picks up the change and the local config file is updated automatically
