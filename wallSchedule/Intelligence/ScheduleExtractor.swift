import UIKit

enum ScheduleExtractor {
    enum ExtractError: Error, LocalizedError {
        case noModelAvailable

        var errorDescription: String? {
            "Нужна iOS 27 или облачная модель в настройках"
        }
    }

    static func extractSchedule(from image: UIImage, targetClassName: String?) async throws -> [ManualLessonEntry] {
        if CloudModelConfig.load().isConfigured {
            return try await CloudScheduleExtractor.extractSchedule(from: image, targetClassName: targetClassName)
        }
        guard #available(iOS 27, *) else { throw ExtractError.noModelAvailable }
        return try await OnDeviceScheduleExtractor.extractSchedule(from: image, targetClassName: targetClassName)
    }
}
