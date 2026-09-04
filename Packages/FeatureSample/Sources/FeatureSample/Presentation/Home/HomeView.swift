import SwiftUI

/// No logic, no formatting, no navigator, no `Task`. It renders state and sends actions.
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.state.heading)
                    .font(.title2)
                Text(viewModel.state.caption)
                    .foregroundColor(.secondary)
                ForEach(viewModel.state.rows) { row in
                    Button(row.title) {
                        viewModel.send(row.action)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
    }
}
