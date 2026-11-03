import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            ExerciseListView(viewModel: dependencies.makeExerciseListViewModel(), dependencies: dependencies)
                .navigationDestination(for: Exercise.self) { exercise in
                    ExerciseDetailView(
                        viewModel: dependencies.makeExerciseDetailViewModel(for: exercise),
                        dependencies: dependencies
                    )
                }
        }
    }
}

#Preview {
    RootView(dependencies: .preview())
}
