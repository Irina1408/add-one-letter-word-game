import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.body.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.75))
            )
            .padding()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(message)
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView(message: "Word already used")
            .previewLayout(.sizeThatFits)
    }
}
