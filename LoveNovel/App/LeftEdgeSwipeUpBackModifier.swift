import SwiftUI

struct LeftEdgeSwipeUpBackGestureEvaluator {
    let edgeWidth: CGFloat
    let minimumVerticalTravel: CGFloat
    let maximumHorizontalDrift: CGFloat

    func shouldTrigger(
        startLocation: CGPoint,
        endLocation: CGPoint,
        translation: CGSize
    ) -> Bool {
        guard startLocation.x <= edgeWidth else {
            return false
        }

        guard endLocation.x <= edgeWidth else {
            return false
        }

        let upwardDistance = -translation.height
        guard upwardDistance >= minimumVerticalTravel else {
            return false
        }

        guard abs(translation.width) <= maximumHorizontalDrift else {
            return false
        }

        return true
    }
}

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
        let evaluator = LeftEdgeSwipeUpBackGestureEvaluator(
            edgeWidth: edgeWidth,
            minimumVerticalTravel: minimumVerticalTravel,
            maximumHorizontalDrift: maximumHorizontalDrift
        )
        guard evaluator.shouldTrigger(
            startLocation: value.startLocation,
            endLocation: value.location,
            translation: value.translation
        ) else {
            return
        }

        perform()
    }
}

public extension View {
    func leftEdgeSwipeUpBackGesture(
        edgeWidth: CGFloat = 14,
        minimumVerticalTravel: CGFloat = 80,
        maximumHorizontalDrift: CGFloat = 24,
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
