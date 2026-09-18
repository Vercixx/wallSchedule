import UIKit

enum ScheduleExtractor {
    enum ExtractError: Error, LocalizedError {
        case noModelAvailable
        case timedOut

        var errorDescription: String? {
            switch self {
            case .noModelAvailable: "Настройте облачную модель в настройках"
            case .timedOut: "Распознавание не дало прогресса слишком долго, попробуйте ещё раз"
            }
        }
    }

    // Cloud path streams (SSE) — URLSession's own idle timeout handles a stuck-but-slow
    // model correctly. This race is only a last-resort backstop for a fully dead flow.
    static func extractSchedule(
        from image: UIImage,
        targetClassName: String?,
        onProgress: @escaping @MainActor (Int) -> Void = { _ in }
    ) async throws -> [ManualLessonEntry] {
        try await withThrowingTaskGroup(of: [ManualLessonEntry].self) { group in
            group.addTask {
                try await run(from: image, targetClassName: targetClassName, onProgress: onProgress)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 300_000_000_000)
                throw ExtractError.timedOut
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    private static func run(
        from image: UIImage,
        targetClassName: String?,
        onProgress: @escaping @MainActor (Int) -> Void
    ) async throws -> [ManualLessonEntry] {
        guard CloudModelConfig.load().isConfigured else { throw ExtractError.noModelAvailable }
        return try await CloudScheduleExtractor.extractSchedule(from: image, targetClassName: targetClassName, onProgress: onProgress)
    }
}
