import UIKit

enum ScheduleExtractor {
    enum ExtractError: Error {
        case noModelAvailable
    }

    static func extractSchedule(from image: UIImage, targetClassName: String?) async throws -> [ManualLessonEntry] {
        if CloudModelConfig.load().isConfigured {
            return try await CloudScheduleExtractor.extractSchedule(from: image, targetClassName: targetClassName)
        }
        guard #available(iOS 27, *) else { throw ExtractError.noModelAvailable }
        return try await OnDeviceScheduleExtractor.extractSchedule(from: image, targetClassName: targetClassName)
    }
}
