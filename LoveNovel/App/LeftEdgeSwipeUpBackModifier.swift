import SwiftUI

private struct LeftEdgeSwipeUpBackModifier: ViewModifier {
    let edgeWidth: CGFloat
    let minimumVerticalTravel: CGFloat
    let maximumHorizontalDrift: CGFloat
    let perform: () -> Void

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 24, coordinateSpace: .local)
                .onEnded(handleDragEnded)
        )
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        guard value.startLocation.x <= edgeWidth else {
            return
        }

        let upwardDistance = -value.translation.height
        guard upwardDistance >= minimumVerticalTravel else {
            return
        }

        guard abs(value.translation.width) <= maximumHorizontalDrift else {
            return
        }

        perform()
    }
}

extension View {
    func leftEdgeSwipeUpBackGesture(
        edgeWidth: CGFloat = 32,
        minimumVerticalTravel: CGFloat = 72,
        maximumHorizontalDrift: CGFloat = 56,
        perform: @escaping () -> Void
    ) -> some View {
        modifier(
            LeftEdgeSwipeUpBackModifier(
                edgeWidth: edgeWidth,
                minimumVerticalTravel: minimumVerticalTravel,
                maximumHorizontalDrift: maximumHorizontalDrift,
                perform: perform
            )
        )
    }
}
