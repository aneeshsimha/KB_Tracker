import SwiftUI
import SwiftData

struct WorkoutLibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.modifiedAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var editing: WorkoutDefinition?
    @State private var running: WorkoutDefinition?
    @State private var confirmDelete: UUID?

    private var presets: [WorkoutDefinition] {
        [
            .builtIn(.emom(kettlebellType: .double, weight: 16, minutes: 10)),
            .builtIn(.rounds(kettlebellType: .double, weight: 16, rounds: 10, restSeconds: 60)),
            .builtIn(.press(kettlebellType: .single, weight: 16, targetLadders: 3)),
            .builtIn(.snatchTest(kettlebellType: .single, weight: 16, minutes: 10)),
            .builtIn(.swingInterval(kettlebellType: .single, weight: 16, rounds: 10, restSeconds: 60))
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Eyebrow("WORKOUT LIBRARY")
                    Spacer()
                    Button { editing = WorkoutDefinition(name: "New workout", blocks: [WorkoutBlock()]) } label: {
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(AppColors.green)
                    }
                    .accessibilityLabel("Create workout")
                }
                if !templates.filter(\.isFavorite).isEmpty {
                    group("FAVORITES", templates.filter(\.isFavorite))
                }
                group("MY WORKOUTS", templates)
                if let last = sessions.first {
                    definitionCard(last.repeatDefinition, subtitle: "Repeat last session", isTemplate: false)
                }
                Text("BUILT-IN STARTERS")
                    .font(AppTypography.mono(12, weight: .semibold))
                    .foregroundStyle(AppColors.ink3)
                ForEach(presets) { preset in definitionCard(preset, subtitle: "Starter", isTemplate: false) }
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { definition in
            WorkoutEditorView(definition: definition) { saved in
                if let existing = templates.first(where: { $0.id == saved.id }) { existing.definition = saved }
                else { context.insert(WorkoutTemplate(definition: saved)) }
                try? context.save()
            }
        }
        .navigationDestination(item: $running) { definition in
            WorkoutRunnerView(definition: definition)
        }
        .alert("Delete workout?", isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let id = confirmDelete, let template = templates.first(where: { $0.id == id }) { context.delete(template); try? context.save() }
                confirmDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmDelete = nil }
        } message: { Text("This removes the saved template. Past sessions stay in history.") }
    }

    private func group(_ title: String, _ items: [WorkoutTemplate]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(AppTypography.mono(12, weight: .semibold)).foregroundStyle(AppColors.ink3)
            if items.isEmpty {
                Text("Build a workout or save a starter to see it here.")
                    .font(AppTypography.bodyText).foregroundStyle(AppColors.ink3)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).kbCard()
            }
            ForEach(items) { template in
                if let definition = template.definition {
                    definitionCard(definition, subtitle: "\(definition.blocks.count) blocks", isTemplate: true, template: template)
                }
            }
        }
    }

    private func definitionCard(_ definition: WorkoutDefinition, subtitle: String, isTemplate: Bool, template: WorkoutTemplate? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(definition.name).font(AppTypography.titleMd).foregroundStyle(AppColors.ink)
                    Text(subtitle).font(AppTypography.mono(12)).foregroundStyle(AppColors.ink3)
                }
                Spacer()
                if let template {
                    Button { template.isFavorite.toggle(); try? context.save() } label: {
                        Image(systemName: template.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(template.isFavorite ? AppColors.green : AppColors.ink2)
                    }
                    .accessibilityLabel(template.isFavorite ? "Remove favorite" : "Favorite")
                }
            }
            Text(definition.blocks.map { $0.name }.joined(separator: " · "))
                .font(AppTypography.mono(12)).foregroundStyle(AppColors.ink2).lineLimit(2)
            HStack(spacing: 14) {
                Button("Start") { running = definition }
                Button(isTemplate ? "Edit" : "Customize") { editing = definition }
                if isTemplate, let template {
                    Button("Duplicate") {
                        var copy = definition
                        copy.id = UUID()
                        copy.name += " copy"
                        context.insert(WorkoutTemplate(definition: copy))
                        try? context.save()
                    }
                    Button("Delete", role: .destructive) { confirmDelete = template.id }
                }
            }
            .font(AppTypography.mono(12, weight: .semibold))
            .foregroundStyle(AppColors.green)
        }
        .padding(16)
        .kbCard()
    }
}
