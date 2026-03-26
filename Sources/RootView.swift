import SwiftUI

struct RootView: View {
    @StateObject private var vm = SessionViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NavigationStack {
                GoalSetupView(vm: vm)
            }
            .tint(.white)
        }
        .preferredColorScheme(.dark)
    }
}
