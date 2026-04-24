import PencilKit
import SwiftUI

struct DrawingDisplay: View {
    let data: Data
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geo in
            if let drawing = try? PKDrawing(data: data), !drawing.strokes.isEmpty {
                let bounds = imageBounds(for: drawing, in: geo.size)
                Image(uiImage: drawing.image(from: bounds, scale: displayScale))
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Dessin")
            } else {
                Color.clear
            }
        }
    }

    // Strokes can extend beyond the canvas bounds that produced them. Use the drawing's own
    // bounding box (padded) so the rendered image captures every stroke regardless of canvas size.
    private func imageBounds(for drawing: PKDrawing, in size: CGSize) -> CGRect {
        let strokeBounds = drawing.bounds.insetBy(dx: -8, dy: -8)
        guard !strokeBounds.isEmpty, strokeBounds.isFinite else {
            return CGRect(origin: .zero, size: size)
        }
        return strokeBounds
    }
}

private extension CGRect {
    var isFinite: Bool {
        origin.x.isFinite && origin.y.isFinite && size.width.isFinite && size.height.isFinite
    }
}
