import SwiftUI
import PhotosUI
import Observation

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - State

    var selectedImage: UIImage?
    var fishHint: String = ""
    var showingImagePicker = false
    var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    var showingPhotoPicker = false
    var isAnalyzing = false
    var analysisViewModel: AnalysisViewModel?

    // MARK: - Computed

    var canAnalyze: Bool {
        selectedImage != nil && !isAnalyzing
    }

    var hasImage: Bool {
        selectedImage != nil
    }

    // MARK: - Actions

    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        imagePickerSourceType = .camera
        showingImagePicker = true
    }

    func openGallery() {
        showingPhotoPicker = true
    }

    func imageSelected(_ image: UIImage) {
        selectedImage = ImageProcessing.prepareForMobile(image)
    }

    func startAnalysis() {
        guard let image = selectedImage else { return }
        analysisViewModel = AnalysisViewModel(
            image: image,
            fishHint: fishHint.isEmpty ? nil : fishHint
        )
        isAnalyzing = true
    }

    func analysisDismissed() {
        isAnalyzing = false
        analysisViewModel = nil
    }

    func reset() {
        selectedImage = nil
        fishHint = ""
        isAnalyzing = false
        analysisViewModel = nil
    }
}
