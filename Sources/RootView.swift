import SwiftUI

struct RootView: View {
    @StateObject private var vm = SessionViewModel()

    var body: some View {
        NavigationStack {
            GoalSetupView(vm: vm)
        }
    }
}
