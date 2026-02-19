import Foundation

actor AsyncGate {
    private var isOpen = false
    private var hasArrived = false
    private var arrivalContinuations: [CheckedContinuation<Void, Never>] = []
    private var gateContinuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        hasArrived = true
        resumeArrivalContinuations()

        guard !isOpen else {
            return
        }

        await withCheckedContinuation { continuation in
            gateContinuations.append(continuation)
        }
    }

    func waitUntilArrived() async {
        guard !hasArrived else {
            return
        }

        await withCheckedContinuation { continuation in
            arrivalContinuations.append(continuation)
        }
    }

    func open() {
        isOpen = true

        guard !gateContinuations.isEmpty else {
            return
        }

        let continuations = gateContinuations
        gateContinuations.removeAll(keepingCapacity: true)
        continuations.forEach { continuation in
            continuation.resume()
        }
    }

    private func resumeArrivalContinuations() {
        guard !arrivalContinuations.isEmpty else {
            return
        }

        let continuations = arrivalContinuations
        arrivalContinuations.removeAll(keepingCapacity: true)
        continuations.forEach { continuation in
            continuation.resume()
        }
    }
}
