import SwiftUI
import DJQuotesDatabase
import DJQuotesDomain
import GRDB

struct QuoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @Bindable var vm: QuoteViewModel
    @State private var selectedStep = QuoteWizardStep.customer

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                wizardProgressBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                TabView(selection: $selectedStep) {
                    StepCustomer(vm: vm).tag(QuoteWizardStep.customer)
                    StepEventDetails(vm: vm).tag(QuoteWizardStep.eventDetails)
                    StepSource(vm: vm).tag(QuoteWizardStep.source)
                    StepCustomize(vm: vm).tag(QuoteWizardStep.customize)
                    StepExtras(vm: vm).tag(QuoteWizardStep.extras)
                    StepPricing(vm: vm).tag(QuoteWizardStep.pricing)
                    StepSummary(vm: vm).tag(QuoteWizardStep.summary)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(selectedStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if selectedStep == .summary {
                        Button(String(localized: "quote.save")) {
                            Task {
                                guard await vm.saveDraft(createdBy: auth.currentProfile?.id ?? "") else { return }
                                dismiss()
                            }
                        }
                        .disabled(vm.isSaving)
                    }
                }
            }
        }
    }

    private var wizardProgressBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(QuoteWizardStep.allCases.enumerated()), id: \.element.rawValue) { index, step in
                HStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(index <= selectedStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.2))
                            .frame(width: 28, height: 28)
                        if index < selectedStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption2.bold())
                                .foregroundStyle(index == selectedStep.rawValue ? .white : .secondary)
                        }
                    }

                    if index < QuoteWizardStep.allCases.count - 1 {
                        Rectangle()
                            .fill(index < selectedStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.2))
                            .frame(height: 2)
                    }
                }
            }
        }
    }
}

// MARK: - Step 1: Customer

struct StepCustomer: View {
    @Bindable var vm: QuoteViewModel
    @State private var customers: [Customer] = []
    @State private var searchText = ""

    var filtered: [Customer] {
        guard !searchText.isEmpty else { return customers }
        return customers.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.phone.contains(searchText) }
    }

    var body: some View {
        VStack {
            if let customer = vm.selectedCustomer {
                VStack(spacing: 8) {
                    Text(customer.name).font(.title3).fontWeight(.semibold)
                    Text(customer.phone).foregroundStyle(.secondary)
                    if let email = customer.email { Text(email).font(.caption).foregroundStyle(.tertiary) }
                    Button(String(localized: "quote.changeCustomer")) { vm.selectedCustomer = nil }.font(.caption)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
                .padding()
            } else {
                List(filtered) { customer in
                    Button { vm.selectedCustomer = customer } label: {
                        VStack(alignment: .leading) {
                            Text(customer.name).font(.headline)
                            Text(customer.phone).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .searchable(text: $searchText)
            }
        }
        .task {
            customers = (try? await DatabaseManager.shared.read { db in
                try Customer.order(Column("name").asc).fetchAll(db)
            }) ?? []
        }
    }
}

// MARK: - Step 2: Event Details

struct StepEventDetails: View {
    @Bindable var vm: QuoteViewModel

    var body: some View {
        Form {
            TextField(String(localized: "quote.eventName"), text: $vm.eventName)
            DatePicker(String(localized: "quote.eventDate"), selection: $vm.eventDate, displayedComponents: .date)
        }
    }
}

// MARK: - Step 3: Source

struct StepSource: View {
    @Bindable var vm: QuoteViewModel
    @State private var packages: [Package] = []

    var body: some View {
        VStack(spacing: 16) {
            Button {
                vm.sourceMode = .scratch
                vm.selectedPackage = nil
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus").font(.largeTitle)
                    Text("quote.source.scratch").font(.headline)
                    Text("quote.source.scratchDescription").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.sourceMode == .scratch && vm.selectedPackage == nil
                    ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Text("quote.source.orPackage").font(.caption).foregroundStyle(.secondary)

            List(packages) { pkg in
                Button {
                    vm.selectPackage(pkg)
                } label: {
                    HStack {
                        Text(pkg.name).font(.headline)
                        Spacer()
                        Text(pkg.pricingMode.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            packages = (try? await DatabaseManager.shared.read { db in
                try Package.filter(Column("isActive") == true).order(Column("name").asc).fetchAll(db)
            }) ?? []
        }
    }
}

// MARK: - Step 4: Customize

struct StepCustomize: View {
    @Bindable var vm: QuoteViewModel

    var body: some View {
        List {
            ForEach(Array($vm.wizardItems.enumerated()), id: \.element.id) { index, $item in
                HStack {
                    TextField(String(localized: "quote.itemLabel"), text: $item.label).font(.subheadline)
                    TextField("0.00", text: $item.unitPrice).keyboardType(.decimalPad).frame(width: 80).font(.subheadline)
                    TextField("1", text: $item.quantity).keyboardType(.numberPad).frame(width: 50).font(.subheadline)
                }
            }
            .onDelete { vm.removeItem(at: $0.first!) }

            Button { vm.addItem(label: "", unitPrice: "0.00", quantity: "1") } label: {
                Label(String(localized: "quote.addItem"), systemImage: "plus")
            }
        }
    }
}

// MARK: - Step 5: Extras

struct StepExtras: View {
    @Bindable var vm: QuoteViewModel

    var body: some View {
        List {
            Section(String(localized: "quote.extras.items")) {
                ForEach(Array($vm.wizardExtras.enumerated()), id: \.element.id) { index, $item in
                    HStack {
                        TextField(String(localized: "quote.itemLabel"), text: $item.label).font(.subheadline)
                        TextField("0.00", text: $item.unitPrice).keyboardType(.decimalPad).frame(width: 80)
                        TextField("1", text: $item.quantity).keyboardType(.numberPad).frame(width: 50)
                    }
                }
                .onDelete { vm.removeExtra(at: $0.first!) }
                Button { vm.addExtra(label: "", unitPrice: "0.00", quantity: "1") } label: {
                    Label(String(localized: "quote.addExtra"), systemImage: "plus")
                }
            }

            Section(String(localized: "quote.installerCount")) {
                Stepper("\(vm.installerCount)", value: $vm.installerCount, in: 0...20)
            }
        }
    }
}

// MARK: - Step 6: Pricing

struct StepPricing: View {
    @Bindable var vm: QuoteViewModel

    var body: some View {
        Form {
            Section(String(localized: "quote.travelCharge")) {
                TextField("0.00", text: $vm.travelCharge).keyboardType(.decimalPad)
            }
            Section(String(localized: "quote.discount")) {
                HStack {
                    TextField("0", text: $vm.discountRate).keyboardType(.decimalPad)
                    Text("%")
                }
            }
            Section(String(localized: "quote.deposit")) {
                TextField("0.00", text: $vm.depositAmount).keyboardType(.decimalPad)
            }
            Section(String(localized: "quote.preview")) {
                LabeledContent(String(localized: "quote.subtotal"), value: vm.subtotal.formatted())
                LabeledContent(String(localized: "quote.extrasSubtotal"), value: vm.extrasSubtotal.formatted())
                LabeledContent(String(localized: "quote.travelCharge"), value: (Money(vm.travelCharge) ?? .zero).formatted())
                let discountAmt = PricingEngine.calculateDiscountAmount(base: vm.subtotal + vm.extrasSubtotal, discountRate: Decimal(string: vm.discountRate) ?? .zero)
                LabeledContent(String(localized: "quote.discount"), value: "-\(discountAmt.formatted())")
                LabeledContent(String(localized: "quote.total"), value: vm.quotedTotal.formatted()).fontWeight(.bold)
                LabeledContent(String(localized: "quote.deposit"), value: (Money(vm.depositAmount) ?? .zero).formatted())
                LabeledContent(String(localized: "quote.balance"), value: vm.quotedBalance.formatted()).fontWeight(.bold)
            }
        }
    }
}

// MARK: - Step 7: Summary

struct StepSummary: View {
    @Bindable var vm: QuoteViewModel
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Form {
            Section(String(localized: "quote.summary.header")) {
                if let customer = vm.selectedCustomer {
                    LabeledContent(String(localized: "quote.customer"), value: customer.name)
                }
                LabeledContent(String(localized: "quote.event"), value: vm.eventName.isEmpty ? "-" : vm.eventName)
                LabeledContent(String(localized: "quote.date"), value: vm.eventDate.formatted(date: .long, time: .omitted))
                LabeledContent(String(localized: "quote.source"), value: vm.sourceMode == .scratch
                    ? String(localized: "quote.source.scratch")
                    : vm.selectedPackage?.name ?? "-")
                LabeledContent(String(localized: "quote.items"), value: "\(vm.wizardItems.count + vm.wizardExtras.count)")
            }

            Section {
                VStack(spacing: 12) {
                    HStack {
                        Text(String(localized: "quote.subtotal"))
                        Spacer()
                        Text(vm.subtotal.formatted())
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(String(localized: "quote.extrasSubtotal"))
                        Spacer()
                        Text(vm.extrasSubtotal.formatted())
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(String(localized: "quote.discount"))
                        Spacer()
                        Text("-\(PricingEngine.calculateDiscountAmount(base: vm.subtotal + vm.extrasSubtotal, discountRate: Decimal(string: vm.discountRate) ?? .zero).formatted())")
                            .foregroundStyle(.red)
                    }
                    Divider()
                    HStack {
                        Text(String(localized: "quote.total"))
                            .fontWeight(.bold)
                        Spacer()
                        Text(vm.quotedTotal.formatted())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 4)
            }

            Section(String(localized: "quote.notes")) {
                TextField(String(localized: "quote.customerNotes"), text: $vm.customerNotes, axis: .vertical)
                TextField(String(localized: "quote.internalNotes"), text: $vm.internalNotes, axis: .vertical)
            }

            Section {
                Button(String(localized: "quote.saveDraft")) {
                    Task {
                        guard await vm.saveDraft(createdBy: auth.currentProfile?.id ?? "") else { return }
                    }
                }
                .disabled(vm.isSaving)

                Button(String(localized: "quote.send")) {
                    Task {
                        guard await vm.saveDraft(createdBy: auth.currentProfile?.id ?? "") else { return }
                        guard await vm.sendQuote() else { return }
                    }
                }
                .disabled(vm.isSaving)
            }
        }
    }
}