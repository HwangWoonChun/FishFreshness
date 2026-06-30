import SwiftUI

struct AnalysisLoadingView: View {

    @Bindable var viewModel: AnalysisViewModel
    var onReanalyze: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showingResult = false
    @State private var waveOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .fullScreenCover(isPresented: $showingResult) {
            resultCover
        }
        .alert("분석 실패", isPresented: failureAlertBinding) {
            Button("확인") { dismiss() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.completedResult?.overallScore) { _, score in
            guard score != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingResult = true
            }
        }
    }

    private var backgroundView: some View {
        Image(uiImage: viewModel.image)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.6))
            .blur(radius: 20)
    }

    private var contentView: some View {
        VStack(spacing: 32) {
            Spacer()
            loadingIndicator
            statusSection
            Spacer()
            cancelButton
        }
    }

    private var loadingIndicator: some View {
        ZStack {
            pulseRing(index: 0)
            pulseRing(index: 1)
            pulseRing(index: 2)

            Image(systemName: "fish.fill")
                .font(.system(size: 52))
                .foregroundStyle(.white)
                .scaleEffect(pulseScale)
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseScale)
        .onAppear { pulseScale = 1.1 }
    }

    private func pulseRing(index: Int) -> some View {
        let i = CGFloat(index)
        return Circle()
            .stroke(Color.white.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
            .frame(width: 80 + i * 40)
            .scaleEffect(pulseScale + i * 0.1)
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            Text(viewModel.state.statusText)
                .font(.headline)
                .foregroundStyle(.white)

            WaveLoadingView(offset: waveOffset)
                .frame(width: 200, height: 4)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        waveOffset = 200
                    }
                }
        }
    }

    private var cancelButton: some View {
        Button {
            viewModel.cancelAnalysis()
            dismiss()
        } label: {
            Text("취소")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
        }
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private var resultCover: some View {
        if let result = viewModel.completedResult {
            ResultView(
                result: result,
                image: viewModel.image,
                record: viewModel.savedRecord,
                onReanalyze: handleReanalyze
            )
        }
    }

    private var failureAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { dismiss() } }
        )
    }

    private func handleReanalyze() {
        showingResult = false
        viewModel.cancelAnalysis()
        dismiss()
        onReanalyze?()
    }
}

// MARK: - Wave Loading Indicator

struct WaveLoadingView: View {
    let offset: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))

                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: -geo.size.width * 0.4 + offset)
                    .clipped()
            }
        }
    }
}

#Preview {
    let vm = AnalysisViewModel(
        image: UIImage(systemName: "fish.fill")!,
        fishHint: "고등어"
    )
    return AnalysisLoadingView(viewModel: vm)
}
