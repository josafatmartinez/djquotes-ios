# DJQuotes iOS

Event Quoter — native iOS app built with SwiftUI.

## Stack

- Swift 6.4
- SwiftUI (iOS 18+)
- GRDB.swift (SQLite)
- Swift Testing

## Packages

| Package | Purpose |
|---|---|
| `DJQuotesDatabase` | SQLite schema, migrations, GRDB models |
| `DJQuotesDomain` | Pricing engine, quote lifecycle, money type, business rules |
| `DJQuotesPDF` | PDF generation with CoreGraphics |

## Setup

```bash
swift build
cd Packages/DJQuotesDomain
swift test
```

## Git Workflow

- Keep `main` deployable.
- Create work from `main`: `feature/<topic>`, `fix/<topic>`, or `chore/<topic>`.
- Open a pull request into `main`. GitHub Actions runs domain tests on every push and pull request.
- Squash merge after CI passes, then delete the remote branch.
- Use Conventional Commits, for example `feat: add quote filters` or `fix: prevent invalid totals`.

Repository is public, so GitHub Free can protect `main` and require CI checks.

## Releases

- App versions use SemVer: `MAJOR.MINOR.PATCH`. Build numbers are increasing integers.
- Run `Prepare release` from GitHub Actions on `main` with target version. It validates domain tests, updates version and `CHANGELOG.md`, then opens a release PR.
- Merge release PR after CI passes. Create annotated tag `vMAJOR.MINOR.PATCH` on `main`.
- Tag workflow validates app version and domain tests, then creates GitHub Release with generated notes.
- GitHub hosted runners provide Xcode 26.6, but this project requires Xcode 27. Run iOS builds locally or add a self-hosted Xcode 27 runner before making iOS build a required CI check.

## Architecture

```
App (SwiftUI Views)
  └─ DJQuotesDomain (pure business logic)
       └─ DJQuotesDatabase (GRDB models + SQLite)
            └─ GRDB.swift
```

## Project Structure

```
App/Sources/App/          # SwiftUI app entry point + views
Packages/
├── DJQuotesDatabase/     # SQLite + GRDB models + migrations
├── DJQuotesDomain/       # Pricing, lifecycle, money, folio
└── DJQuotesPDF/          # PDF rendering (Phase 4)
```

## Status

Phase 0 — Foundation. Schema, models, and domain layer in progress.
