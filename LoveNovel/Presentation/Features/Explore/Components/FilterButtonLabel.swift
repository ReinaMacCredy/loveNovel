import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct FilterButtonLabel: View {
    var body: some View {
        Image(systemName: "slider.horizontal.3")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.55))
            .frame(width: 44, height: 44)
    }
}
