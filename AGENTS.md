# DJQuotes iOS — Agent Instructions

## Build & Run

```bash
# Build for simulator (Xcode 27.0, SDK 27.0, iOS 18.0+ target)
xcodebuild -project DJQuotes.xcodeproj \
  -scheme DJQuotes \
  -destination "platform=iOS Simulator,name=FreelanceFinance iOS 26 iPhone,OS=26.5" \
  -sdk iphonesimulator \
  -derivedDataPath /tmp/dd build

# Install & launch
xcrun simctl boot <DEVICE_UUID> 2>/dev/null
xcrun simctl install <DEVICE_UUID> /tmp/dd/Build/Products/Debug-iphonesimulator/DJQuotes.app
xcrun simctl launch <DEVICE_UUID> com.josafatmartinez.djquotes

# Take screenshot for OCR verification
xcrun simctl io <DEVICE_UUID> screenshot /tmp/verify.png
swift /tmp/ocr.swift /tmp/verify.png
```

Devices: `FreelanceFinance iOS 26 iPhone` (90CF584B-...), `DJQuotes Simulator` (311C6079-...). Both iOS 26.5.

## Architecture

```
DJQuotes.xcodeproj (workspace: container:DJQuotes.xcodeproj)
├── App/Sources/App/
│   ├── DJQuotesApp.swift          — @main entry, AuthManager + SyncManager environment
│   ├── Auth/
│   │   ├── AuthManager.swift      — @Observable, PIN+biometrics auth, multi-profile
│   │   ├── ProfilePickerView.swift — Login gate + OnboardingCreateProfileView
│   │   ├── PinEntryView.swift     — PIN input with shake animation + haptics
│   │   ├── CreateProfileView.swift — Form for new profiles (no role picker)
│   │   └── ProfileListView.swift  — List + toggle active/inactive
│   ├── Navigation/
│   │   ├── AppRouter.swift        — AppTab enum (dashboard, customers, quotes, catalog, settings)
│   │   └── AuthGateView.swift     — Auth state routing + MainTabView + SettingsView + DashboardView
│   ├── Features/
│   │   ├── Catalog/     — CatalogListView, CatalogItemFormView, CatalogViewModel
│   │   ├── Customers/   — CustomerListFullView, CustomerFormView, CustomerViewModel
│   │   ├── Packages/    — PackageListView, PackageFormView, PackageViewModel
│   │   ├── Quotes/      — QuoteViewModel, QuoteListView, QuoteEditorView (7-step wizard), QuoteDetailView
│   │   └── Settings/    — WorkerRolesView, WorkerRoleViewModel
│   ├── Sync/            — SyncManager, SyncMessage, SyncPairingView, SyncSettingsView, SyncDataExporter/Importer
│   └── Resources/
│       ├── Localizable.xcstrings    — 165 keys en+es (21 have values, rest auto-extracted)
│       └── Assets.xcassets/AppIcon  — Blue circle + "DQ" 1024px PNG
├── Packages/
│   ├── DJQuotesDatabase/   — GRDB models (11 tables), migrations, DatabaseManager
│   ├── DJQuotesDomain/     — Money (Decimal), PricingEngine, QuoteLifecycle, QuoteFolioGenerator
│   └── DJQuotesPDF/        — QuotePDFGenerator (CGContext, A4), depends on DB+Domain
├── Config/Project.xcconfig
├── App/Info.plist
└── App/DJQuotes.entitlements
```

## Conventions

- **Money**: stored as TEXT canoncial string in DB, never REAL/float. `Money` struct wraps `Decimal`, locale `es_MX`.
- **Folio format**: `COT-YYYY-NNNNN`.
- **GRDB models**: all `public` + `Identifiable` + `Hashable`. Explicit `public init`.
- **No roles**: flat permissions. All profiles can do everything. `ProfileRole` enum deleted (Phase 5).
- **P2P sync**: `sync_registry` table ready. MultipeerConnectivity in `SyncManager`. Quotes stay local.
- **pbxproj**: OpenStep format, `PBXFileSystemSynchronizedRootGroup`. Manual edits require `plutil -convert xml1` first.
- **Localization**: `Text("key")` = LocalizedStringKey → looks up in catalog. No `tableName: nil`.
- **Auth**: SHA256(pin), LAContext biometrics, multi-profile via toggle.
- **Quote lifecycle**: raw strings ("DRAFT", "SENT", ...) in Domain, QuoteStatus enum in Database.

## Xcode details

- Version: 27.0 (SDK 27.0/26.5 sim runtime)
- Team: `DM4FD3PCWX`, bundle ID: `com.josafatmartinez.djquotes`
- Deployment target: iOS 18.0
- Swift: 6.4, GRDB.swift 7.11.1
- `PBXFileSystemSynchronizedRootGroup` auto-detects new files under `App/Sources/App/`

## Testing

```bash
# Domain tests (23 tests, Swift Testing)
xcodebuild test -project DJQuotes.xcodeproj -scheme DJQuotesDomain \
  -destination "platform=iOS Simulator,name=FreelanceFinance iOS 26 iPhone,OS=26.5"
```

## Git

Repo: `https://github.com/josafatmartinez/djquotes-ios`. Branch: `main`. Push after each feature commit.