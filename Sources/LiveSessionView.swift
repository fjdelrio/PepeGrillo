import SwiftUI

struct LiveSessionView: View {
    @ObservedObject var vm: SessionViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.mode.rawValue + " • " + vm.outputMode.rawValue)
                        .font(.headline)
                    Text(vm.objective)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Toggle(isOn: $vm.isListening) {
                    Text(vm.isListening ? "Listening" : "Off")
                        .font(.subheadline)
                }
                .toggleStyle(.switch)
                .frame(maxWidth: 160)
            }
            .padding(.horizontal)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GroupBox("Live transcript") {
                        Text(vm.transcript.isEmpty ? "(waiting for speech…)" : vm.transcript)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.callout)
                            .textSelection(.enabled)
                    }

                    GroupBox("Suggestions") {
                        if vm.suggestions.isEmpty {
                            Text("No suggestions yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(vm.suggestions) { s in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(s.title).font(.headline)
                                        Spacer()
                                        if let lang = s.language {
                                            Text(lang == .es ? "ES" : "EN")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    ForEach(s.bullets, id: \.self) { b in
                                        Text("• \(b)")
                                            .font(.callout)
                                    }
                                }
                                .padding(.vertical, 6)

                                Divider()
                            }
                        }
                    }

                    Button {
                        Task { await vm.forceFullAdviceNow() }
                    } label: {
                        Text("Deep advice (on-demand)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if let last = vm.suggestions.first, vm.speakSuggestions {
                        Button {
                            vm.speak(latest: last)
                        } label: {
                            Text("Speak latest suggestion")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }

            HStack {
                Button(role: .destructive) {
                    vm.stopSession()
                } label: {
                    Text("End")
                }

                Spacer()

                NavigationLink {
                    SummaryView(vm: vm)
                } label: {
                    Text("Summary")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .navigationTitle("Live")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: vm.isListening) { _, newValue in
            if newValue { vm.startSession() }
            else { vm.pauseListening() }
        }
        .onAppear {
            // If the user lands here, do not auto-start; let them toggle.
        }
    }
}
