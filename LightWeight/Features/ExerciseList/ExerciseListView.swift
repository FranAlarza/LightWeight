import SwiftUI

struct ExerciseListView: View {
    @State private var viewModel: ExerciseListViewModel
    @State private var isAddingExercise = false
    @State private var isShowingSettings = false
    private let dependencies: AppDependencies

    init(viewModel: ExerciseListViewModel, dependencies: AppDependencies) {
        _viewModel = State(initialValue: viewModel)
        self.dependencies = dependencies
    }

    var body: some View {
        content
            .navigationTitle("Ejercicios")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Ajustes", systemImage: "gearshape") { isShowingSettings = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Añadir ejercicio", systemImage: "plus") { isAddingExercise = true }
                }
            }
            .sheet(isPresented: $isAddingExercise, onDismiss: viewModel.load) {
                AddExerciseView(viewModel: dependencies.makeAddExerciseViewModel())
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(settings: dependencies.settings)
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
        if viewModel.hasLoaded && viewModel.summaries.isEmpty {
            ContentUnavailableView {
                Label("Sin ejercicios", systemImage: "dumbbell")
            } description: {
                Text("Añade tu primer ejercicio para empezar a registrar tus pesos.")
            } actions: {
                Button("Añadir ejercicio") { isAddingExercise = true }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                ForEach(viewModel.sections) { section in
                    Section(section.group.title) {
                        ForEach(section.items) { summary in
                            NavigationLink(value: summary.exercise) {
                                ExerciseRow(summary: summary, preferredUnit: viewModel.settings.preferredUnit)
                            }
                            .contextMenu { muscleGroupMenu(for: summary) }
                        }
                        .onDelete { offsets in
                            offsets.map { section.items[$0] }.forEach(viewModel.delete)
                        }
                    }
                }
            }
        }
    }

    private func muscleGroupMenu(for summary: ExerciseSummary) -> some View {
        Menu("Grupo muscular", systemImage: "figure.strengthtraining.traditional") {
            ForEach(MuscleGroup.allCases) { group in
                Button {
                    viewModel.move(summary, to: group)
                } label: {
                    if group == summary.exercise.muscleGroup {
                        Label(group.title, systemImage: "checkmark")
                    } else {
                        Text(group.title)
                    }
                }
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

private struct ExerciseRow: View {
    let summary: ExerciseSummary
    let preferredUnit: WeightUnit

    var body: some View {
        HStack(spacing: 12) {
            ExerciseThumbnail(url: summary.exercise.imageURL)
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.exercise.name)
                    .font(.headline)
                if let lastSet = summary.lastSet {
                    Text("Última: \(lastSet.summary) · \(lastSet.performedAt.formatted(.dateTime.day().month()))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Sin registros")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let record = summary.personalRecord {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("PR")
                        .font(.caption2.bold())
                        .foregroundStyle(.tint)
                    Text(record.weight.converted(to: preferredUnit).formatted)
                        .font(.subheadline.monospacedDigit())
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        ExerciseListView(viewModel: dependencies.makeExerciseListViewModel(), dependencies: dependencies)
    }
}

#Preview("Vacío") {
    let dependencies = AppDependencies.preview(withSampleData: false)
    NavigationStack {
        ExerciseListView(viewModel: dependencies.makeExerciseListViewModel(), dependencies: dependencies)
    }
}
