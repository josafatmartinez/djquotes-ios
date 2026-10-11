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
swift test
```

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