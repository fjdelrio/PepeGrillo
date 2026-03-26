import SwiftUI

private struct CapsuleOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black : Color.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.white : Color.black)
                .overlay(
                    Capsule().stroke(Color.white, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct GoalSetupView: View {
    @ObservedObject var vm: SessionViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("PepeGrillo")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Session")
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        CapsuleOptionButton(title: "Interview", isSelected: vm.mode == .interview) {
                            vm.mode = .interview
                        }
                        CapsuleOptionButton(title: "Meeting", isSelected: vm.mode == .meeting) {
                            vm.mode = .meeting
                        }
                        CapsuleOptionButton(title: "Social", isSelected: vm.mode == .social) {
                            vm.mode = .social
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Objective")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        TextField("What do you want to achieve?", text: $vm.objective, axis: .vertical)
                            .lineLimit(3...8)
                            .textInputAutocapitalization(.sentences)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 1)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Output")
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        CapsuleOptionButton(title: "Nudges", isSelected: vm.outputMode == .nudges) {
                            vm.outputMode = .nudges
                        }
                        CapsuleOptionButton(title: "Full", isSelected: vm.outputMode == .full) {
                            vm.outputMode = .full
                        }
                        CapsuleOptionButton(title: "Cluely", isSelected: vm.outputMode == .cluely) {
                            vm.outputMode = .cluely
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Options")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Picker("Language", selection: $vm.languageMode) {
                        ForEach(LanguageMode.allCases) { l in
                            Text(l.rawValue).tag(l)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Speak suggestions out loud (TTS)", isOn: $vm.speakSuggestions)
                        .tint(.white)

                    Toggle("Granola-style summary at end", isOn: $vm.generateSummaryAtEnd)
                        .tint(.white)
                }

                NavigationLink {
                    LiveSessionView(vm: vm)
                } label: {
                    Text("Start Session")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(vm.objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(vm.objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
            }
            .padding(16)
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
    }
}
