import SwiftUI

struct LiveSessionView: View {
    @ObservedObject var vm: SessionViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.mode.rawValue + " • " + vm.outputMode.rawValue)
                            .font(.headline)

                        Text(vm.objective)
                            .font(.caption)
                            .opacity(0.8)
                            .lineLimit(2)
                    }

                    Spacer()

                    Toggle(isOn: $vm.isListening) {
                        Text(vm.isListening ? "Listening" : "Off")
                            .font(.subheadline)
                    }
                    .toggleStyle(.switch)
                    .tint(.white)
                    .frame(maxWidth: 160)
                }
                .padding(.horizontal)

                Divider().overlay(Color.white.opacity(0.35))

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
                                    .opacity(0.75)
                            } else {
                                ForEach(vm.suggestions) { s in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(s.title).font(.headline)
                                            Spacer()
                                            if let lang = s.language {
                                                Text(lang == .es ? "ES" : "EN")
                                                    .font(.caption2)
                                                    .opacity(0.75)
                                            }
                                        }
                                        ForEach(s.bullets, id: \.self) { b in
                                            Text("• \(b)")
                                                .font(.callout)
                                        }
                                    }
                                    .padding(.vertical, 6)

                                    Divider().overlay(Color.white.opacity(0.25))
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
                        .tint(.white)

                        if let last = vm.suggestions.first, vm.speakSuggestions {
                            Button {
                                vm.speak(latest: last)
                            } label: {
                                Text("Speak latest suggestion")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white)
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
                    .tint(.white)

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
            .foregroundStyle(.white)
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
