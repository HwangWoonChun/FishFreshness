import UIKit
import CoreImage
import Vision

// MARK: - Image Content Assessment

struct ImageContentAssessment: Sendable {
    let classifications: [(label: String, confidence: Float)]
    let colors: String
    let dimensions: String
    let brightness: String
    let aspectRatio: String

    var topSubjectLabel: String? {
        classifications.first?.label
    }

    var detectedSubjectSummary: String {
        guard !classifications.isEmpty else { return "식별 불가" }
        return classifications
            .prefix(5)
            .map { "\($0.label) (\(Int($0.confidence * 100))%)" }
            .joined(separator: ", ")
    }

    var fishConfidence: Float {
        classifications
            .filter { Self.matchesFishLabel($0.label) }
            .map(\.confidence)
            .max() ?? 0
    }

    var nonFishFoodConfidence: Float {
        classifications
            .filter { Self.matchesNonFishFoodLabel($0.label) }
            .map(\.confidence)
            .max() ?? 0
    }

    var shouldRejectAsNonFish: Bool {
        guard !classifications.isEmpty else { return false }
        return nonFishFoodConfidence >= 0.12 && fishConfidence < 0.08
    }

    var promptDescription: String {
        let classificationBlock: String
        if classifications.isEmpty {
            classificationBlock = "Vision classification: unavailable (use color signals only)"
        } else {
            let lines = classifications.prefix(8).map {
                "- \($0.label): \(String(format: "%.0f", $0.confidence * 100))%"
            }
            classificationBlock = """
            Vision image classification (primary subject evidence):
            \(lines.joined(separator: "\n"))
            """
        }

        return """
        === IMAGE SIGNALS ===
        \(classificationBlock)

        Dimensions: \(dimensions)
        Brightness: \(brightness)
        Framing: \(aspectRatio)
        Color analysis by region: \(colors)
        === END IMAGE SIGNALS ===
        """
    }

    private static func matchesFishLabel(_ label: String) -> Bool {
        let normalized = label.lowercased().replacingOccurrences(of: "_", with: " ")
        let fishKeywords = [
            "fish", "seafood", "salmon", "tuna", "mackerel", "cod", "trout", "sardine",
            "anchovy", "herring", "snapper", "bass", "carp", "eel", "squid", "octopus",
            "shrimp", "prawn", "crab", "lobster", "shellfish", "oyster", "clam", "mussel",
            "scallop", "roe", "sashimi", "sea bream", "flatfish", "sole", "halibut",
            "perch", "pike", "mullet", "seafood market"
        ]
        return fishKeywords.contains { normalized.contains($0) }
    }

    private static func matchesNonFishFoodLabel(_ label: String) -> Bool {
        let normalized = label.lowercased().replacingOccurrences(of: "_", with: " ")
        let nonFishKeywords = [
            "meat", "beef", "pork", "chicken", "poultry", "lamb", "steak", "patty",
            "burger", "rib", "meatball", "sausage", "ham", "bacon", "grill", "barbecue",
            "bbq", "cooked", "dish", "meal", "dinner", "lunch", "cuisine", "vegetable",
            "fruit", "bread", "dessert", "cake", "pasta", "rice", "noodle", "sandwich",
            "pizza", "soup", "stew", "fried", "roast", "processed food", "prepared food"
        ]
        return nonFishKeywords.contains { normalized.contains($0) }
    }
}

// MARK: - Vision Preprocessing Service

nonisolated struct VisionPreprocessingService: Sendable {

    func assessImageContent(from image: UIImage) async -> ImageContentAssessment {
        guard let cgImage = image.cgImage else {
            return ImageContentAssessment(
                classifications: [],
                colors: "unknown",
                dimensions: "invalid image",
                brightness: "unknown",
                aspectRatio: "unknown"
            )
        }

        let classifications = await classifyImage(
            cgImage,
            orientation: cgImageOrientation(for: image)
        )
        let colors = analyzeColors(cgImage)
        let dimensions = "\(cgImage.width)x\(cgImage.height) px"
        let brightness = describeOverallBrightness(cgImage)
        let aspectRatio = describeAspectRatio(width: cgImage.width, height: cgImage.height)

        return ImageContentAssessment(
            classifications: classifications,
            colors: colors,
            dimensions: dimensions,
            brightness: brightness,
            aspectRatio: aspectRatio
        )
    }

    // MARK: - Vision Classification

    private func classifyImage(
        _ cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async -> [(label: String, confidence: Float)] {
        let request = ClassifyImageRequest(.revision2)
        let handler = ImageRequestHandler(cgImage, orientation: orientation)

        do {
            let results = try await handler.perform(request)
            return results
                .sorted { $0.confidence > $1.confidence }
                .prefix(10)
                .map { ($0.identifier, $0.confidence) }
        } catch {
            return []
        }
    }

    private func cgImageOrientation(for image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    // MARK: - Color Analysis

    private func analyzeColors(_ cgImage: CGImage) -> String {
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        let extent = ciImage.extent

        let regions: [(name: String, rect: CGRect)] = [
            ("overall", extent),
            ("top", CGRect(
                x: extent.minX + extent.width * 0.2,
                y: extent.minY + extent.height * 0.55,
                width: extent.width * 0.6,
                height: extent.height * 0.35
            )),
            ("center", CGRect(
                x: extent.minX + extent.width * 0.25,
                y: extent.minY + extent.height * 0.25,
                width: extent.width * 0.5,
                height: extent.height * 0.5
            )),
        ]

        var colorDescriptions: [String] = []
        for region in regions {
            if let avgColor = averageColor(of: ciImage, in: region.rect, context: context) {
                colorDescriptions.append("\(region.name): \(describeColor(avgColor))")
            }
        }

        if colorDescriptions.isEmpty {
            return "unknown"
        }
        return colorDescriptions.joined(separator: "; ")
    }

    private func averageColor(of image: CIImage, in rect: CGRect, context: CIContext) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: rect), forKey: "inputExtent")
        guard let output = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(output,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())

        return (CGFloat(bitmap[0]) / 255,
                CGFloat(bitmap[1]) / 255,
                CGFloat(bitmap[2]) / 255)
    }

    private func describeColor(_ color: (r: CGFloat, g: CGFloat, b: CGFloat)) -> String {
        let r = color.r, g = color.g, b = color.b
        let brightness = (r + g + b) / 3
        let saturation = max(r, g, b) - min(r, g, b)

        var desc = ""
        if brightness > 0.7 { desc += "bright " }
        else if brightness < 0.3 { desc += "dark " }
        else { desc += "medium " }

        if saturation < 0.1 { desc += "grey/desaturated" }
        else if r > g && r > b { desc += "reddish-pink" }
        else if g > r && g > b { desc += "greenish" }
        else if b > r && b > g { desc += "bluish-silver" }
        else if r > 0.7 && g > 0.5 { desc += "yellowish-orange" }
        else { desc += "mixed" }

        return desc
    }

    private func describeOverallBrightness(_ cgImage: CGImage) -> String {
        guard let avg = averageColor(of: CIImage(cgImage: cgImage), in: CIImage(cgImage: cgImage).extent, context: CIContext()) else {
            return "unknown"
        }
        let brightness = (avg.r + avg.g + avg.b) / 3
        if brightness > 0.65 { return "well lit" }
        if brightness > 0.35 { return "moderately lit" }
        return "low light"
    }

    private func describeAspectRatio(width: Int, height: Int) -> String {
        guard width > 0, height > 0 else { return "unknown" }
        let ratio = Double(width) / Double(height)
        if ratio > 1.4 { return "landscape/wide shot" }
        if ratio < 0.75 { return "portrait/tall shot" }
        return "square-ish/standard shot"
    }
}

enum PreprocessingError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "유효하지 않은 이미지입니다."
        }
    }
}

// MARK: - Image Processing

enum ImageProcessing {

    /// Longest edge limit for images selected in the app (gallery/camera).
    static let mobileSelectionMaxDimension: CGFloat = 2048

    /// Longest edge limit before sending to Foundation Models analysis.
    static let analysisMaxDimension: CGFloat = 768

    /// Longest edge limit for history thumbnails stored in SwiftData.
    static let thumbnailMaxDimension: CGFloat = 320

    /// Normalizes EXIF orientation and downscales large gallery photos for mobile use.
    static func prepareForMobile(
        _ image: UIImage,
        maxDimension: CGFloat = mobileSelectionMaxDimension
    ) -> UIImage {
        downscale(normalizeOrientation(image), maxDimension: maxDimension)
    }

    /// Downscales while preserving aspect ratio. Returns the original if already small enough.
    static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let pixelSize = pixelDimensions(of: image)
        guard pixelSize.width > 0, pixelSize.height > 0 else { return image }

        let longestEdge = max(pixelSize.width, pixelSize.height)
        guard longestEdge > maxDimension else { return normalizeOrientation(image) }

        let scale = maxDimension / longestEdge
        let targetSize = CGSize(
            width: (pixelSize.width * scale).rounded(.down),
            height: (pixelSize.height * scale).rounded(.down)
        )
        guard targetSize.width > 0, targetSize.height > 0 else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Renders the image upright so gallery EXIF orientation is applied.
    static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let pixelSize = pixelDimensions(of: image)
        guard pixelSize.width > 0, pixelSize.height > 0 else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: pixelSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
        }
    }

    static func jpegData(
        from image: UIImage,
        maxDimension: CGFloat = thumbnailMaxDimension,
        quality: CGFloat = 0.65
    ) -> Data? {
        downscale(image, maxDimension: maxDimension).jpegData(compressionQuality: quality)
    }

    private static func pixelDimensions(of image: UIImage) -> CGSize {
        guard let cgImage = image.cgImage else {
            return CGSize(
                width: image.size.width * image.scale,
                height: image.size.height * image.scale
            )
        }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }
}
