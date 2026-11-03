import SwiftUI

struct SettingsView: View {
    @Bindable var settings: UserSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Unidad preferida", selection: $settings.preferredUnit) {
                        ForEach(WeightUnit.allCases) { Text($0.title).tag($0) }
                    }
                } footer: {
                    Text("Se usa en las gráficas y los récords. Cada serie conserva la unidad con la que la registraste.")
                }

                Section("Créditos") {
                    Link(WgerExerciseCatalog.attribution, destination: WgerExerciseCatalog.websiteURL)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hecho") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView(settings: UserSettings())
}
