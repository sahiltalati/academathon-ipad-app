import SwiftUI
import PencilKit

struct WhiteboardView: View {
    let booking: Booking
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var showSaveConfirmation = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.studentName)
                        .font(.headline)
                    Text("\(booking.subject) · \(Self.dateFormatter.string(from: booking.startTime))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Save Drawing") {
                    saveDrawing()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)

            CanvasView(canvasView: $canvasView, toolPicker: toolPicker)
                .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Saved!", isPresented: $showSaveConfirmation) {
            Button("OK") {}
        } message: {
            Text("Drawing saved to your files.")
        }
    }

    private func saveDrawing() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        guard let data = image.pngData() else { return }
        let filename = "lesson_\(booking.id)_\(Int(Date().timeIntervalSince1970)).png"
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? data.write(to: dir.appendingPathComponent(filename))
        showSaveConfirmation = true
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let toolPicker: PKToolPicker

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
