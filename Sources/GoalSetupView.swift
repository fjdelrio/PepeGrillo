import SwiftUI

struct GoalSetupView: View {
    @ObservedObject var vm: SessionViewModel

    var body: some View {
        Form {
            Section("Person") {
                Picker("Profile", selection: $vm.selectedPersonId) {
                    Text("(New…)").tag(UUID?.none)
                    ForEach(vm.peopleStore.people) { p in
                        Text(p.name).tag(UUID?.some(p.id))
                    }
                }

                TextField("Name", text: $vm.personName)
                TextField("Notes (optional)", text: $vm.personNotes, axis: .vertical)
                    .lineLimit(2...6)
            }

            Section("Session") {
                Picker("Mode", selection: $vm.mode) {
                    ForEach(SessionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                TextField("Objective (what do you want to achieve?)", text: $vm.objective, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("Options") {
                Picker("Output", selection: $vm.outputMode) {
                    ForEach(OutputMode.allCases) { o in
                        Text(o.rawValue).tag(o)
                    }
                }

                Picker("Language", selection: $vm.languageMode) {
                    ForEach(LanguageMode.allCases) { l in
                        Text(l.rawValue).tag(l)
                    }
                }

                Toggle("Speak suggestions out loud (TTS)", isOn: $vm.speakSuggestions)
                Toggle("Granola-style summary at end", isOn: $vm.generateSummaryAtEnd)
            }

            Section {
                NavigationLink {
                    LiveSessionView(vm: vm)
                } label: {
                    Text("Start Session")
                        .font(.headline)
                }
                .disabled(vm.objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("PepeGrillo")
    }
}
