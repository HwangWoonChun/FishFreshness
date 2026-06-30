import SwiftUI
import PhotosUI
import SwiftData

struct HomeView: View {

    @State private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext

    // PhotosPicker
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    heroSection
                    imagePreviewSection
                    fishHintSection
                    actionButtonsSection
                    analyzeButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("생선 신선도 체크")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
        // Camera picker
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePickerView(sourceType: viewModel.imagePickerSourceType) { image in
                viewModel.imageSelected(image)
            }
            .ignoresSafeArea()
        }
        // Gallery picker (PhotosUI)
        .photosPicker(
            isPresented: $viewModel.showingPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.imageSelected(image)
                }
                selectedPhotoItem = nil
            }
        }
        // Analysis loading fullscreen
        .fullScreenCover(isPresented: $viewModel.isAnalyzing, onDismiss: {
            viewModel.analysisDismissed()
        }) {
            if let analysisVM = viewModel.analysisViewModel {
                AnalysisLoadingView(viewModel: analysisVM) {
                    viewModel.analysisDismissed()
                    viewModel.startAnalysis()
                }
                .onAppear {
                    analysisVM.startAnalysis(modelContext: modelContext)
                }
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "fish.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolEffect(.bounce, options: .repeating.speed(0.3))
            Text("생선 사진을 찍어\n신선도를 즉시 확인하세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var imagePreviewSection: some View {
        Group {
            if let image = viewModel.selectedImage {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                    .overlay(alignment: .topTrailing) {
                        Button {
                            viewModel.reset()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white, Color(.systemGray3))
                        }
                        .padding(12)
                    }
                    .transition(.scale.combined(with: .opacity))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "fish")
                                .font(.system(size: 40))
                                .foregroundStyle(.quaternary)
                            Text("이미지를 선택하거나 촬영하세요")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(duration: 0.4), value: viewModel.hasImage)
    }

    private var fishHintSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("어종 힌트 (선택사항)", systemImage: "text.cursor")
                .font(.footnote)
                .foregroundStyle(.secondary)
            TextField("예: 고등어, 연어, 도미...", text: $viewModel.fishHint)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
        }
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.openCamera()
            } label: {
                Label("카메라", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityLabel("카메라로 촬영")

            Button {
                viewModel.openGallery()
            } label: {
                Label("갤러리", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityLabel("갤러리에서 선택")
        }
    }

    private var analyzeButton: some View {
        Button {
            viewModel.startAnalysis()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("신선도 분석하기")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.canAnalyze)
        .animation(.default, value: viewModel.canAnalyze)
    }
}

// MARK: - Image Picker Wrapper

struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImagePicked: onImagePicked) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        init(onImagePicked: @escaping (UIImage) -> Void) { self.onImagePicked = onImagePicked }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            picker.dismiss(animated: true)
            if let image { onImagePicked(image) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: FishScanRecord.self, inMemory: true)
}
