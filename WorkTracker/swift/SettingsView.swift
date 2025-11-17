import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Definições")
                .font(.title2)
                .bold()

            HStack {
                Text("€ por hora:")
                Spacer()
                TextField("Valor", value: $settings.hourlyRate, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
            }
            .padding(.horizontal)

            Button("Fechar") {
                dismiss()
            }
            .padding(.top)
            .keyboardShortcut(.return, modifiers: [])

            Spacer()
        }
        .padding()
        .frame(minWidth: 300)
    }
}
