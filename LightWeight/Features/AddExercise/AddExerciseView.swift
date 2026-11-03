import SwiftUI

struct AddExerciseView: View {
    @State private var viewModel: AddExerciseViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddExerciseViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.canCreateCustom {
                    Section {
                        Menu {
                            ForEach(MuscleGroup.allCases) { group in
                                Button(group.title) {
                                    if viewModel.addCustom(muscleGroup: group) { dismiss() }
                                }
                            }
                        } label: {
                            Label("Crear «\(viewModel.trimmedQuery)»", systemImage: "plus.circle")
                        }
                    } footer: {
                        Text("Elige el grupo muscular del nuevo ejercicio.")
                    }
                }
                catalogSection
            }
            .navigationTitle("Nuevo ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar o crear ejercicio")
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .task(id: viewModel.query) {
                // Debounce typing; the catalog is cached after the first load.
                if !viewModel.results.isEmpty {
                    do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
                }
                await viewModel.search()
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var catalogSection: some View {
        switch viewModel.catalogState {
        case .idle, .loading:
            HStack {
                Spacer()
                ProgressView("Cargando catálogo…")
                Spacer()
            }
            .listRowBackground(Color.clear)
        case .failed:
            ContentUnavailableView(
                "Catálogo no disponible",
                systemImage: "wifi.slash",
                description: Text("Comprueba tu conexión. Mientras tanto puedes escribir el nombre y crear un ejercicio personalizado.")
            )
        case .loaded:
            ForEach(viewModel.sections) { section in
                Section(section.group.title) {
                    ForEach(section.items) { item in
                        Button {
                            if viewModel.add(item) { dismiss() }
                        } label: {
                            HStack(spacing: 12) {
                                ExerciseThumbnail(url: item.imageURL)
                                Text(item.name)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            Section {
            } footer: {
                Link(WgerExerciseCatalog.attribution, destination: WgerExerciseCatalog.websiteURL)
                    .font(.footnote)
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

#Preview {
    AddExerciseView(viewModel: AppDependencies.preview().makeAddExerciseViewModel())
}
