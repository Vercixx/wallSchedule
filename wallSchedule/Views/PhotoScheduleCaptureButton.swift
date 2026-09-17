import SwiftUI
import UIKit

struct PhotoScheduleCaptureButton: View {
    let label: String
    let targetClassName: String?
    let onExtracted: ([ManualLessonEntry]) -> Void

    @State private var showingCamera = false
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(isProcessing ? "Распознаю…" : label) {
                showingCamera = true
            }
            .disabled(isProcessing)
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { image in
                showingCamera = false
                guard let image else { return }
                Task { await process(image) }
            }
        }
    }

    private func process(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let entries = try await ScheduleExtractor.extractSchedule(from: image, targetClassName: targetClassName)
            guard !entries.isEmpty else {
                errorMessage = "Не удалось распознать расписание на фото"
                return
            }
            onExtracted(entries)
        } catch {
            errorMessage = "Ошибка распознавания: \(error.localizedDescription)"
        }
    }
}
