import SwiftUI
import DJQuotesDatabase

enum AppRoute: Hashable { case pinEntry(Profile) }
enum AppTab: String, CaseIterable {
    case dashboard, customers, quotes, catalog, settings
    var label: String {
        switch self {
        case .dashboard: String(localized: "tab.dashboard")
        case .customers: String(localized: "tab.customers")
        case .quotes: String(localized: "tab.quotes")
        case .catalog: String(localized: "tab.catalog")
        case .settings: String(localized: "tab.settings")
        }
    }
    var icon: String {
        switch self {
        case .dashboard: "rectangle.grid.1x2"
        case .customers: "person.2"
        case .quotes: "doc.text"
        case .catalog: "square.grid.2x2"
        case .settings: "gearshape"
        }
    }
}