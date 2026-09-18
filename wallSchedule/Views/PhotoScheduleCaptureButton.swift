import SwiftUI
import UIKit

struct PhotoScheduleCaptureButton: View {
    let label: String
    let targetClassName: String?
    let onExtracted: ([ManualLessonEntry]) -> Void

    @State private var showingCamera = false
    @State private var isProcessing = false
    @State private var receivedChars = 0
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(buttonTitle) {
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

    private var buttonTitle: String {
        guard isProcessing else { return label }
        // Approximate — counts characters received, not real tokens (no tokenizer available client-side).
        return receivedChars > 0 ? "Распознаю… (\(receivedChars) симв.)" : "Распознаю…"
    }

    private func process(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        receivedChars = 0
        defer { isProcessing = false }

        do {
            let entries = try await ScheduleExtractor.extractSchedule(
                from: image,
                targetClassName: targetClassName
            ) { count in
                receivedChars = count
            }
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
