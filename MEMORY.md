# MEMORY — DJQuotes iOS Project State

## Current State (Oct 12, 2026)
Branch: main. Build: Xcode 27.0, Simulator iOS 26.5.

### Previous Feature Commits
1. `d9a62b6` — fix: inject missing en/es translations for all UI keys
2. `72222d0` — chore: set deployment target to 18.0
3. `9e57762` — style: HIG refinement for onboarding, PIN entry, and splash
4. `266f627` — feat: add AppIcon placeholder, refine iconography, enable dark mode compatibility
5. `4fb9c4d` — style: HIG refinement for feature views — avatar, catalog icons, wizard steps, status colors
6. `233a8ac` — fix: reduce tabs to 5, move Packages into Settings to fix double navigation bar
7. `29c9806` — feat: PDF generation with CGContext + share sheet export in QuoteDetailView
8. `9f0f690` — fix: prevent self-disable of current profile in ProfileListView
9. `4e81fd9` — refactor: remove roles, flat permissions — all users can do everything; add deviceId, sync_registry table
10. `ca12134` — feat: P2P sync via MultipeerConnectivity — pairing, snapshot export/import, sync settings
11. `beec08a` — feat: Dashboard with status cards + recent quotes; QuoteListView filter by status; QuoteDetail auto-refresh; Summary visual improvements

### Delivery
- Public GitHub repository. `main` requires a pull request and passing `Domain tests`; force-push and deletion are disabled.
- CI runs `swift test` for `DJQuotesDomain` on pushes and pull requests.
- Release preparation is manual from GitHub Actions. It updates SemVer, increments build number, updates `CHANGELOG.md`, and opens a release pull request.
- Tag `vMAJOR.MINOR.PATCH` validates app version and domain tests, then creates GitHub Release notes.
- App version: `1.0.0`; build number: `1`. No release tag exists yet.
- GitHub hosted runners use Xcode 26.6. This project needs Xcode 27, so iOS builds run locally until a self-hosted Xcode 27 runner exists.

### Phase status
- Phase 0: ✅ Project, SPM, DB, models, migrations
- Phase 1: ✅ Auth (PIN, biometrics, multi-profile, onboarding)
- Phase 2: ✅ CRUD Catalog, Customers, Packages, Worker Roles
- Phase 3: ✅ Quote wizard (7 steps), pricing, lifecycle
- Phase 4: ✅ PDF generation + share sheet
- Phase 5: ✅ Remove roles, flat permissions, deviceId, sync_registry
- Phase 6: ✅ P2P sync (MultipeerConnectivity) — pairing, snapshot, sync settings
- Phase 7: ✅ Dashboard + Quote improvements (filter, auto-refresh, Summary UX)

### Key design decisions
- No roles: all users have equal permissions. Differentiation via sync P2P (source device shares catalog/customers/packages).
- 5 tabs max: Dashboard, Customers, Quotes, Catalog, Settings. Packages inside Settings.
- Money as TEXT (canonical string), Money struct with Decimal, locale es_MX.
- All SPM models public + Identifiable + Hashable + explicit init.
- pbxproj OpenStep format, PBXFileSystemSynchronizedRootGroup.
- Localization: 165 keys en+es in Localizable.xcstrings.
- AppIcon: blue circle + "DQ" 1024 PNG.
- No CocoaPods or Fastlane.

### Known issues
- DJQuotes Simulator (iOS 26.5) has runtime incompatibility with SDK 27.0. Use FreelanceFinance iOS 26 iPhone or download iOS 27 runtime.
- TestFlight not configured.
- Hosted GitHub runners cannot build this Xcode 27 project.
- Android (Jetpack Compose) placeholder repo only, not started.

### Next
- TestFlight distribution setup
- Real device testing with 2 iPhones for P2P sync validation
- Self-hosted Xcode 27 runner for required iOS CI build
- Android development
