import SwiftUI

/// Square exercise image with a dumbbell placeholder for custom exercises or failed loads.
struct ExerciseThumbnail: View {
    let url: URL?
    var size: CGFloat = 48

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                Image(systemName: "dumbbell")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        // wger images are drawings on white, so keep a white tile in dark mode too.
        .background(url == nil ? Color(.secondarySystemFill) : .white, in: .rect(cornerRadius: 10))
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ExerciseThumbnail(url: URL(string: "https://wger.de/media/exercise-images/91/Crunches-1.png.200x200_q85.png"))
        ExerciseThumbnail(url: nil)
    }
}
