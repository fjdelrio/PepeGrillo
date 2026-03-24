import SwiftUI

struct SummaryView: View {
    @ObservedObject var vm: SessionViewModel

    var body: some View {
        Form {
            Section("Status") {
                Text(vm.isListening ? "Listening is ON" : "Listening is OFF")
                Text("Suggestions generated: \(vm.suggestions.count)")
            }

            Section("Summary") {
                if let summary = vm.summary {
                    Text(summary.notes)
                        .textSelection(.enabled)

                    if !summary.actionItems.isEmpty {
                        Divider()
                        Text("Action items")
                            .font(.headline)
                        ForEach(summary.actionItems, id: \.self) { a in
                            Text("• \(a)")
                        }
                    }

                    if !summary.followUps.isEmpty {
                        Divider()
                        Text("Follow-ups")
                            .font(.headline)
                        ForEach(summary.followUps, id: \.self) { f in
                            Text("• \(f)")
                        }
                    }
                } else {
                    Text("No summary yet.")
                        .foregroundStyle(.secondary)

                    Button {
                        vm.generateSummary()
                    } label: {
                        Text("Generate summary")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle("Summary")
    }
}
