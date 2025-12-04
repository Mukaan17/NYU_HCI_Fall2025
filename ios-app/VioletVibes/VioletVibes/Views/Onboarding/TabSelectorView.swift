import SwiftUI

struct TabSelectorView: View {
    @Binding var isSignUpMode: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Login Tab
            Button(action: {
                withAnimation(.spring()) { isSignUpMode = false }
            }) {
                VStack(spacing: 6) {
                    Text("Log In")
                        .font(.headline)
                        .foregroundColor(isSignUpMode ? .white.opacity(0.5) : .white)

                    Rectangle()
                        .fill(isSignUpMode ? Color.clear : Color.white)
                        .frame(height: 3)
                }
                .frame(maxWidth: .infinity)
            }

            // Sign Up Tab
            Button(action: {
                withAnimation(.spring()) { isSignUpMode = true }
            }) {
                VStack(spacing: 6) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(isSignUpMode ? .white : .white.opacity(0.5))

                    Rectangle()
                        .fill(isSignUpMode ? Color.white : Color.clear)
                        .frame(height: 3)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
