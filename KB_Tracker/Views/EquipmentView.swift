import SwiftUI
import SwiftData

struct EquipmentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \EquipmentRecord.weightKg) private var equipment: [EquipmentRecord]
    @State private var editing: EquipmentRecord?
    @State private var showingEditor = false
    @State private var load = 16.0
    @State private var count = 1
    @State private var unit: WeightUnit = .kg
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Eyebrow("YOUR BELLS")
                    Spacer()
                    Button { beginEdit(nil) } label: { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(AppColors.green) }
                        .accessibilityLabel("Add kettlebell")
                }
                if equipment.isEmpty {
                    Text("Add the kettlebells you own to keep your loads handy.")
                        .font(AppTypography.bodyText).foregroundStyle(AppColors.ink2)
                        .padding(20).frame(maxWidth: .infinity, alignment: .leading).kbCard()
                }
                ForEach(equipment) { bell in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(WeightUnit.kg.label(bell.weightKg))
                                .font(AppTypography.mono(24, weight: .semibold)).foregroundStyle(AppColors.ink)
                            Text("\(bell.count) \(bell.count == 1 ? "bell" : "bells") · \(WeightUnit.lb.label(bell.weightKg))")
                                .font(AppTypography.mono(12)).foregroundStyle(AppColors.ink3)
                        }
                        Spacer()
                        Button { beginEdit(bell) } label: { Image(systemName: "pencil").foregroundStyle(AppColors.ink2) }
                        Button(role: .destructive) { context.delete(bell); try? context.save() } label: { Image(systemName: "trash").foregroundStyle(AppColors.red) }
                    }
                    .padding(16).kbCard()
                }
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                Form {
                    Section("Kettlebell") {
                        Picker("Unit", selection: $unit) {
                            Text("kg").tag(WeightUnit.kg)
                            Text("lb").tag(WeightUnit.lb)
                        }.pickerStyle(.segmented)
                        HStack {
                            Text("Load per bell")
                            Spacer()
                            TextField("Load", value: Binding(get: { unit.display(load) }, set: { load = unit.kilograms($0) }), format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                                .frame(width: 90)
                            Text(unit.rawValue)
                        }
                        Stepper("Quantity: \(count)", value: $count, in: 1...100)
                        if let error { Text(error).font(.footnote).foregroundStyle(AppColors.red) }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
                .navigationTitle(editing == nil ? "Add bell" : "Edit bell")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingEditor = false } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func beginEdit(_ bell: EquipmentRecord?) {
        editing = bell
        unit = .kg
        load = bell?.weightKg ?? 16
        count = bell?.count ?? 1
        error = nil
        showingEditor = true
    }

    private func save() {
        let kg = load
        guard kg.isFinite, kg > 0, kg <= 500 else { error = "Enter a positive load up to 500 kg."; return }
        if let editing {
            editing.weightKg = kg
            editing.count = count
            editing.modifiedAt = Date()
        } else {
            context.insert(EquipmentRecord(weightKg: kg, count: count))
        }
        try? context.save()
        showingEditor = false
    }
}
