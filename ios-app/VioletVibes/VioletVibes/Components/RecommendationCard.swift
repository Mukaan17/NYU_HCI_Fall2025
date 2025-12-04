import SwiftUI

struct RecommendationCard: View {

    let recommendation: Recommendation
    let session: UserSession
    let preferences: UserPreferences
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {

                // Image
                if let url = recommendation.image,
                   let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Color.gray.opacity(0.2)
                        }
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // Title
                Text(recommendation.title)
                    .font(.title3.bold())
                    .foregroundColor(.white)

                // Subtitle
                if let desc = recommendation.description {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }

                HStack {
                    if let walk = recommendation.walkTime {
                        Text("🚶‍♀️ \(walk)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    if let rating = recommendation.rating {
                        Text("⭐️ \(String(format: "%.1f", rating))")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
