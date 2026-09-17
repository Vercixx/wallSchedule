import UIKit

enum ScheduleExtractor {
    enum ExtractError: Error, LocalizedError {
        case noModelAvailable
        case timedOut

        var errorDescription: String? {
            switch self {
            case .noModelAvailable: "Нужна iOS 27 или облачная модель в настройках"
            case .timedOut: "Распознавание заняло слишком много времени, попробуйте ещё раз"
            }
        }
    }

    // Neither URLSession nor LanguageModelSession guarantee an upper bound on their own —
    // race against a timeout so the UI never hangs forever.
    static func extractSchedule(from image: UIImage, targetClassName: String?) async throws -> [ManualLessonEntry] {
        try await withThrowingTaskGroup(of: [ManualLessonEntry].self) { group in
            group.addTask {
                try await run(from: image, targetClassName: targetClassName)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 60_000_000_000)
                throw ExtractError.timedOut
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    private static func run(from image: UIImage, targetClassName: String?) async throws -> [ManualLessonEntry] {
        if CloudModelConfig.load().isConfigured {
            return try await CloudScheduleExtractor.extractSchedule(from: image, targetClassName: targetClassName)
        }
        guard #available(iOS 27, *) else { throw ExtractError.noModelAvailable }
        return try await OnDeviceScheduleExtractor.extractSchedule(from: image, targetClassName: targetClassName)
    }
}
