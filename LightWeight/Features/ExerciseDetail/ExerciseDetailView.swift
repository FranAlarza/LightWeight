import SwiftUI

struct ExerciseDetailView: View {
    private enum SetFormRoute: Identifiable {
        case create
        case edit(WorkoutSet)

        var id: String {
            switch self {
            case .create: "create"
            case .edit(let set): set.id.uuidString
            }
        }
    }

    @State private var viewModel: ExerciseDetailViewModel
    @State private var setFormRoute: SetFormRoute?
    private let dependencies: AppDependencies

    init(viewModel: ExerciseDetailViewModel, dependencies: AppDependencies) {
        _viewModel = State(initialValue: viewModel)
        self.dependencies = dependencies
    }

    var body: some View {
        content
            .navigationTitle(viewModel.exercise.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Añadir serie", systemImage: "plus") { setFormRoute = .create }
                }
            }
            .sheet(item: $setFormRoute, onDismiss: viewModel.load) { route in
                SetFormView(viewModel: dependencies.makeSetFormViewModel(mode: mode(for: route)))
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.hasLoaded && !viewModel.hasSets {
            ContentUnavailableView {
                Label("Sin series", systemImage: "list.bullet.rectangle")
            } description: {
                Text("Registra tu primera serie para ver tu progreso.")
            } actions: {
                Button("Añadir serie") { setFormRoute = .create }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                chartSection
                if let record = viewModel.personalRecord {
                    Section("Récord personal") {
                        SetRow(set: record, showsDate: true)
                    }
                }
                ForEach(viewModel.history) { day in
                    Section(day.day.formatted(.dateTime.weekday(.wide).day().month(.wide).year())) {
                        ForEach(day.sets) { set in
                            Button { setFormRoute = .edit(set) } label: { SetRow(set: set, showsDate: false) }
                                .foregroundStyle(.primary)
                                .swipeActions {
                                    Button("Borrar", systemImage: "trash", role: .destructive) { viewModel.delete(set) }
                                }
                        }
                    }
                }
            }
        }
    }

    private var chartSection: some View {
        Section {
            Picker("Métrica", selection: $viewModel.metric) {
                ForEach(ProgressMetric.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            ProgressChartView(
                points: viewModel.chartPoints,
                dateDomain: viewModel.chartDateDomain,
                valueDomain: viewModel.chartValueDomain,
                metric: viewModel.metric,
                unit: viewModel.unit
            )
            Picker("Rango", selection: $viewModel.range) {
                ForEach(ChartRange.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .listRowSeparator(.hidden)
    }

    private func mode(for route: SetFormRoute) -> SetFormViewModel.Mode {
        switch route {
        case .create: .create(exerciseID: viewModel.exercise.id)
        case .edit(let set): .edit(set)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

private struct SetRow: View {
    let set: WorkoutSet
    let showsDate: Bool

    var body: some View {
        HStack {
            Text(set.summary)
                .font(.body.monospacedDigit())
            Spacer()
            Text(showsDate ? set.performedAt.formatted(date: .abbreviated, time: .omitted) : set.performedAt.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let exercise = try! dependencies.repository.exercises().first!
    NavigationStack {
        ExerciseDetailView(viewModel: dependencies.makeExerciseDetailViewModel(for: exercise), dependencies: dependencies)
    }
}
