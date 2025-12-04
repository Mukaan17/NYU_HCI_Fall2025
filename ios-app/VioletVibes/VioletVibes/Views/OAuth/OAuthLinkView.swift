import SwiftUI

struct OAuthLinkView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Google Calendar Linked!")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Your free-time suggestions will now use your schedule.")
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Continue") {
                dismiss()
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8).ignoresSafeArea())
    }
}
