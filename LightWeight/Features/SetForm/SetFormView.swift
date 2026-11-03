import SwiftUI

struct SetFormView: View {
    @State private var viewModel: SetFormViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isWeightFocused: Bool

    init(viewModel: SetFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Peso", value: $viewModel.weightValue, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isWeightFocused)
                            .font(.title2.monospacedDigit())
                        Picker("Unidad", selection: $viewModel.unit) {
                            ForEach(WeightUnit.allCases) { Text($0.symbol).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }
                    Stepper(value: $viewModel.reps, in: 1...100) {
                        LabeledContent("Repeticiones", value: "\(viewModel.reps)")
                    }
                } header: {
                    Text("Serie")
                }

                Section {
                    DatePicker("Fecha", selection: $viewModel.performedAt, in: ...Date.now)
                }

                if !viewModel.isEditing {
                    Section {
                        Button("Guardar y añadir otra", systemImage: "plus.square.on.square") {
                            viewModel.saveAndAddAnother()
                        }
                        .disabled(!viewModel.canSave)
                    } footer: {
                        if viewModel.savedCount > 0 {
                            Text("Series guardadas: \(viewModel.savedCount)")
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Editar serie" : "Nueva serie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.savedCount > 0 ? "Cerrar" : "Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if viewModel.save() { dismiss() }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear { isWeightFocused = viewModel.weightValue == nil }
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
    let dependencies = AppDependencies.preview()
    let exercise = try! dependencies.repository.exercises().first!
    SetFormView(viewModel: dependencies.makeSetFormViewModel(mode: .create(exerciseID: exercise.id)))
}
