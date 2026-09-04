import SwiftUI

/// Renders `state` and sends actions. Every string it shows is already formatted.
struct PinView: View {
    @ObservedObject var viewModel: PinViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.state.heading)
                .font(.title3)
            Text(viewModel.state.instruction)
                .foregroundColor(.secondary)
            Text(viewModel.state.entry)
                .font(.system(.title, design: .monospaced))
            keypad
            actions
            if let caption = viewModel.state.attemptsCaption {
                Text(caption)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            if let message = viewModel.state.inlineErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .onAppear {
            viewModel.send(.onAppear)
        }
    }

    private var keypad: some View {
        HStack(spacing: 8) {
            ForEach(Self.digits, id: \.self) { digit in
                Button(digit) {
                    viewModel.send(.digitEntered(digit))
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Delete") {
                viewModel.send(.backspaceTapped)
            }
            Button("Submit") {
                viewModel.send(.submitTapped)
            }
            .disabled(viewModel.state.isSubmitDisabled)
            Button("Cancel") {
                viewModel.send(.cancelTapped)
            }
        }
        .buttonStyle(.bordered)
    }

    private static let digits = ["1", "2", "3", "4", "5", "6"]
}
