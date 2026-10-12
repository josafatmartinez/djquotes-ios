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
