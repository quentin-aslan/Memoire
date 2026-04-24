import PencilKit
import SwiftUI

struct DrawingCanvas: UIViewRepresentable {
    @Binding var data: Data?
    var isActive: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(data: $data)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false

        // Default ink: white pen on dark background — matches the app's dark luxury aesthetic
        // and guarantees the stroke is visible from the first mark.
        canvas.tool = PKInkingTool(.pen, color: .white, width: 4)

        if let data, let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        canvas.delegate = context.coordinator
        context.coordinator.canvas = canvas
        context.coordinator.toolPicker = PKToolPicker()
        context.coordinator.toolPicker?.addObserver(canvas)

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // Only overwrite the canvas drawing when the external data differs — avoids clobbering
        // in-progress strokes while the user is drawing.
        if let data, let incoming = try? PKDrawing(data: data) {
            if canvas.drawing.dataRepresentation() != incoming.dataRepresentation() {
                canvas.drawing = incoming
            }
        } else if data == nil, !canvas.drawing.strokes.isEmpty {
            canvas.drawing = PKDrawing()
        }

        context.coordinator.setActive(isActive)
    }

    static func dismantleUIView(_ canvas: PKCanvasView, coordinator: Coordinator) {
        coordinator.toolPicker?.setVisible(false, forFirstResponder: canvas)
        coordinator.toolPicker?.removeObserver(canvas)
        canvas.resignFirstResponder()
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var dataBinding: Binding<Data?>
        weak var canvas: PKCanvasView?
        var toolPicker: PKToolPicker?
        private var isActive: Bool = false

        init(data: Binding<Data?>) {
            self.dataBinding = data
        }

        func setActive(_ active: Bool) {
            guard active != isActive else { return }
            isActive = active
            guard let canvas else { return }
            if active {
                // Defer to next runloop so the view is in the window hierarchy when we request focus.
                DispatchQueue.main.async { [weak self] in
                    guard let self, let canvas = self.canvas else { return }
                    canvas.becomeFirstResponder()
                    self.toolPicker?.setVisible(true, forFirstResponder: canvas)
                }
            } else {
                toolPicker?.setVisible(false, forFirstResponder: canvas)
                canvas.resignFirstResponder()
            }
        }

        func canvasViewDrawingDidChange(_ canvas: PKCanvasView) {
            let drawing = canvas.drawing
            if drawing.strokes.isEmpty {
                if dataBinding.wrappedValue != nil {
                    dataBinding.wrappedValue = nil
                }
            } else {
                dataBinding.wrappedValue = drawing.dataRepresentation()
            }
        }
    }
}
