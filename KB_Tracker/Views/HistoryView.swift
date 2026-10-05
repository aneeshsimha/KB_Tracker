// HistoryView.swift
// KB_Tracker
//
// List of past sessions (history.jsx): top stat tiles, 8-week training-arc
// heatmap, and sessions grouped by relative week. Each row taps into detail.

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var loadFilter = ""
    @AppStorage("kb_weight_unit") private var unit: WeightUnit = .kg
    @State private var useDateRange = false
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var endDate = Date.now
    @State private var selectedType: WorkoutType? = nil
    @State private var statusFilter = 0
    @State private var showManual = false
    @State private var backupDocument: KBBackupDocument?
    @State private var showBackupExporter = false
    @State private var showBackupImporter = false
    @State private var importPreview: BackupService.Preview?
    @State private var importError: String?

    // MARK: - Derived totals

    private var totalSessions: Int { sessions.count }
    private var totalRounds: Int { sessions.reduce(0) { $0 + $1.workSets } }
    private var totalHours: Double { sessions.reduce(0.0) { $0 + $1.totalDuration } / 3600 }

    private var filteredSessions: [WorkoutSession] {
        let requestedLoad = Double(loadFilter).map(unit.kilograms)
        return sessions.filter { session in
            let text = query.isEmpty || "\(session.displayTitle) \(session.notes ?? "")".localizedCaseInsensitiveContains(query)
            let loads = session.definition?.blocks.map(\.loadKg) ?? [Double(session.weight)]
            let loadMatches = loadFilter.isEmpty || (requestedLoad.map { target in target.isFinite && target > 0 && loads.contains { abs($0 - target) < 0.0001 } } ?? false)
            let rangeEnd = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
            let dateMatches = !useDateRange || (session.date >= Calendar.current.startOfDay(for: startDate) && session.date < rangeEnd)
            let statusMatches = statusFilter == 0 || (statusFilter == 1 ? session.isCompleted : !session.isCompleted)
            return text && loadMatches && dateMatches && statusMatches && (selectedType == nil || session.workoutType == selectedType)
        }
    }
    private var groups: [WeekGroup] { groupByWeek(filteredSessions) }
    private var exportCSV: String { WorkoutExporter.csv(from: sessions) }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // top stats
                        HStack(spacing: 8) {
                            Mini(label: "SESSIONS", value: "\(totalSessions)")
                            Mini(label: "WORK SETS", value: "\(totalRounds)")
                            Mini(label: "HOURS", value: String(format: "%.1f", totalHours))
                        }
                        .padding(.bottom, 18)

                        // 8-week training arc heatmap
                        WeekStrip(sessions: filteredSessions)

                        filters

                        if filteredSessions.isEmpty {
                            VStack(spacing: 10) {
                                Eyebrow("NO SESSIONS YET")
                                Text("Finish a workout and it'll land here.")
                                    .font(AppTypography.bodyText)
                                    .foregroundColor(AppColors.ink2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }

                        // grouped list
                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Eyebrow(group.label)
                                    Spacer()
                                    Eyebrow("\(group.items.count) ×", color: AppColors.ink4)
                                }
                                VStack(spacing: 8) {
                                    ForEach(group.items) { session in
                                        NavigationLink {
                                            HistoryDetailView(session: session)
                                        } label: {
                                            SessionRow(session: session)
                                        }
                                        .buttonStyle(TapScaleStyle())
                                        .accessibilityIdentifier("history-session-\(session.id.uuidString)")
                                        .accessibilityLabel("\(session.displayTitle), \(session.date.formatted(date: .abbreviated, time: .omitted)), \(session.workSets) sets, \(session.isCompleted ? "completed" : "partial")")
                                    }
                                }
                            }
                            .padding(.top, 22)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: startDate) { _, value in if endDate < value { endDate = value } }
        .sheet(isPresented: $showManual) { NavigationStack { ManualSessionView() } }
        .fileExporter(isPresented: $showBackupExporter, document: backupDocument, contentType: .json, defaultFilename: "kb-tracker-backup") { result in
            backupDocument = nil
            if case .failure(let error) = result { importError = error.localizedDescription }
        }
        .fileImporter(isPresented: $showBackupImporter, allowedContentTypes: [.json]) { result in
            do { let url = try result.get(); let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }; let data = try Data(contentsOf: url); importPreview = try BackupService.preview(data: data, context: modelContext) }
            catch { importError = error.localizedDescription }
        }
        .alert("Backup", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) { Button("OK", role: .cancel) {} } message: { Text(importError ?? "") }
        .confirmationDialog("Import backup?", isPresented: Binding(get: { importPreview != nil }, set: { if !$0 { importPreview = nil } })) { Button("Import") { if let preview = importPreview { do { try BackupService.import(preview, context: modelContext); importPreview = nil } catch { importError = error.localizedDescription } } }; Button("Cancel", role: .cancel) { importPreview = nil } } message: { Text(importPreview.map { "\($0.newSessions) new sessions and \($0.updates) matching sessions will be merged. Newer changes win." } ?? "") }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            IconButton(icon: .back) { dismiss() }
            Spacer()
            Eyebrow("HISTORY")
            Spacer()
            Menu {
                Button("Add manual session") { showManual = true }
                Button("Export backup") { do { backupDocument = try KBBackupDocument(archive: BackupService.archive(context: modelContext)); showBackupExporter = true } catch { importError = error.localizedDescription } }
                Button("Import backup") { showBackupImporter = true }
            } label: {
                Image(systemName: "ellipsis.circle").font(.system(size: 18, weight: .semibold)).foregroundColor(AppColors.ink)
            }
            ShareLink(
                item: exportCSV,
                preview: SharePreview("KB Tracker Sessions", image: Image(systemName: "figure.strengthtraining.traditional"))
            ) {
                Image(systemName: KBIcon.share.rawValue)
                    .font(.system(size: 32 * 0.42, weight: .semibold))
                    .foregroundColor(AppColors.ink)
                    .frame(width: 32, height: 32)
                    .background(AppColors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.hairline, lineWidth: 1))
            }
            .buttonStyle(TapScaleStyle())
            .disabled(sessions.isEmpty)
        }
        .frame(height: 32)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var filters: some View {
        VStack(spacing: 8) {
            TextField("Search notes or workout", text: $query).textFieldStyle(.roundedBorder)
            HStack {
                Menu(selectedType?.title ?? "All workouts") { Button("All workouts") { selectedType = nil }; ForEach(WorkoutType.allCases) { type in Button(type.title) { selectedType = type } } }
                Spacer()
                Picker("Status", selection: $statusFilter) { Text("All").tag(0); Text("Complete").tag(1); Text("Partial").tag(2) }.pickerStyle(.segmented).frame(maxWidth: 210)
            }
            HStack { TextField("Load (\(unit.rawValue))", text: $loadFilter).textFieldStyle(.roundedBorder); Toggle("Date range", isOn: $useDateRange).font(.caption).fixedSize() }
            if !loadFilter.isEmpty && !(Double(loadFilter).map { $0.isFinite && $0 > 0 } ?? false) { Text("Enter a positive numeric load in \(unit.rawValue).").font(.caption).foregroundColor(AppColors.red) }
            if useDateRange { HStack { DatePicker("From", selection: $startDate, displayedComponents: .date); DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: .date) } }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Mini stat tile

/// Small stat tile (history.jsx Mini): eyebrow label + 24pt mono value.
fileprivate struct Mini: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(label, size: 10)
            Text(value)
                .font(AppTypography.mono(24))
                .kerning(-0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kbCard()
    }
}

// MARK: - Week strip (8-week heatmap)

/// 8-week training-arc heatmap (history.jsx WeekStrip): 56 day cells colored
/// by session count, oldest week (W1) left → most recent (W8) right.
fileprivate struct WeekStrip: View {
    let sessions: [WorkoutSession]

    private var buckets: [Int] { weekStripBuckets(sessions) }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow("8 WEEK ARC")
                Spacer()
                Eyebrow("RECENT →", color: AppColors.ink4)
            }
            .padding(.bottom, 10)

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(buckets.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(cellColor(buckets[i]))
                        .frame(height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(AppColors.hairline, lineWidth: 1)
                        )
                }
            }
            .padding(.bottom, 8)

            HStack {
                ForEach(1...8, id: \.self) { w in
                    Text("W\(w)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(AppColors.ink4)
                    if w < 8 { Spacer() }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kbCard()
    }

    private func cellColor(_ count: Int) -> Color {
        switch count {
        case 0: return AppColors.surface2
        case 1: return Color.white.opacity(0.4)
        default: return AppColors.ink
        }
    }
}

// MARK: - Session row

/// One past session (history.jsx SessionRow): date block, mode + weight,
/// completed/target · duration, a micro spark chart, and a chevron.
fileprivate struct SessionRow: View {
    let session: WorkoutSession

    private var isPress: Bool { session.workoutType == .press }

    private var workoutTitle: String {
        switch session.workoutType {
        case .abc:          return session.mode == .emom ? "EMOM" : "Rounds"
        case .snatchTest:   return "Snatch Test"
        case .swingInterval: return "Swing Interval"
        case .press:        return "Press"
        case .custom:       return session.displayTitle
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // date block
            VStack(spacing: 2) {
                Text(session.date.formatted(.dateTime.day()))
                    .font(AppTypography.mono(22))
                Eyebrow(session.date.formatted(.dateTime.month(.abbreviated)), size: 9)
            }
            .frame(width: 36)
            .padding(.trailing, 14)
            .overlay(alignment: .trailing) {
                Rectangle().fill(AppColors.hairline).frame(width: 1)
            }

            // main — press: reps · ladders; otherwise: done/target · duration
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(session.definition == nil ? workoutTitle : session.displayTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.ink)
                    Text(session.weightDisplay)
                        .font(AppTypography.mono(13, weight: .semibold))
                        .foregroundColor(AppColors.ink3)
                }
                HStack(spacing: 0) {
                    Text(session.definition == nil ? "\(isPress ? session.totalReps : session.completedRounds)" : "\(session.workSets)")
                        .font(AppTypography.mono(12.5, weight: .semibold))
                        .foregroundColor(AppColors.ink2)
                    Text(session.definition == nil ? (isPress ? " reps" : "/\(session.targetRounds)") : " sets")
                        .font(.system(size: 12.5))
                        .foregroundColor(AppColors.ink4)
                    Text("  ·  ")
                        .font(.system(size: 12.5))
                        .foregroundColor(AppColors.ink4)
                    Text(session.definition == nil ? (isPress ? "\(session.completedLadders) ladders" : session.totalDuration.formattedMinutesSecondsPadded) : "\(session.recordedReps.map { "\($0) reps" } ?? "– reps") · \(session.isCompleted ? "done" : "partial")")
                        .font(AppTypography.mono(12.5, weight: .regular))
                        .foregroundColor(AppColors.ink2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // micro spark
            let sparkTimes = isPress ? session.ladderReps.map { TimeInterval($0) } : session.setTimes
            if !sparkTimes.isEmpty {
                SparkBars(times: sparkTimes,
                          mode: isPress ? .rounds : session.mode,
                          height: 20,
                          limit: 20)
                    .frame(width: 60)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.ink4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kbCard()
    }
}

// MARK: - Grouping / formatting helpers

/// One relative-week bucket of sessions ("THIS WEEK", "LAST WEEK", "N WEEKS AGO").
fileprivate struct WeekGroup: Identifiable {
    let id: Int            // weeks-ago index
    let label: String
    var items: [WorkoutSession]
}

/// Group sessions (newest first) by whole weeks elapsed since today.
fileprivate func groupByWeek(_ sessions: [WorkoutSession]) -> [WeekGroup] {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let sorted = sessions.sorted { $0.date > $1.date }

    var groups: [WeekGroup] = []
    for s in sorted {
        let day = cal.startOfDay(for: s.date)
        let days = cal.dateComponents([.day], from: day, to: today).day ?? 0
        let wk = max(0, days / 7)
        let label = wk == 0 ? "THIS WEEK" : wk == 1 ? "LAST WEEK" : "\(wk) WEEKS AGO"
        if let idx = groups.lastIndex(where: { $0.id == wk }) {
            groups[idx].items.append(s)
        } else {
            groups.append(WeekGroup(id: wk, label: label, items: [s]))
        }
    }
    return groups
}

/// 56-day counts (oldest → newest) for the 8-week heatmap.
fileprivate func weekStripBuckets(_ sessions: [WorkoutSession]) -> [Int] {
    let days = 56
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    var buckets = Array(repeating: 0, count: days)
    for s in sessions {
        let day = cal.startOfDay(for: s.date)
        let diff = cal.dateComponents([.day], from: day, to: today).day ?? -1
        if diff >= 0 && diff < days {
            buckets[days - 1 - diff] += 1
        }
    }
    return buckets
}

#Preview {
    let config = WorkoutSession(mode: .emom, kettlebellType: .double, weight: 20, targetRounds: 20)
    config.completedRounds = 18
    config.totalDuration = 1140
    config.setTimes = [42, 45, 48, 51, 44, 47, 62, 55, 43, 46]

    return NavigationStack {
        HistoryView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
