import SwiftUI
import PencilKit

// MARK: - Canvas Page Model

class CanvasPage: Identifiable {
    let id = UUID()
    let canvas = PKCanvasView()
}

// MARK: - Whiteboard View

struct WhiteboardView: View {
    let booking: Booking

    @Environment(\.dismiss) private var dismiss

    @State private var pages: [CanvasPage] = [CanvasPage()]
    @State private var toolPicker = PKToolPicker()
    @State private var currentPage = 0
    @State private var showSaveConfirmation = false
    @State private var showGallery = false
    @State private var showAISheet = false
    @State private var isAILoading = false
    @State private var aiExplanation: String?
    @State private var aiErrorMessage: String?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack(spacing: 12) {

                // Custom back button (replaces system nav bar)
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                        Text("Lessons")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Theme.accent)
                }

                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.tutorName ?? "Unknown Tutor")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(booking.subject ?? "No subject") · \(Self.dateFormatter.string(from: booking.startTime))")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Text("Page \(currentPage + 1) of \(pages.count)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.surface)
                    .clipShape(Capsule())

                Button {
                    addPage()
                } label: {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .foregroundStyle(Theme.accent)
                        .imageScale(.large)
                }

                Button {
                    showGallery = true
                } label: {
                    Image(systemName: "photo.stack")
                        .foregroundStyle(Theme.accent)
                        .imageScale(.large)
                }

                // AI Explain button
                Button {
                    explainWithAI()
                } label: {
                    HStack(spacing: 6) {
                        if isAILoading {
                            ProgressView().tint(.white).scaleEffect(0.75)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Explain")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: "7C3AED"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
                }
                .disabled(isAILoading)

                Button("Save Page") {
                    savePage()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
            }
            .padding()
            .background(Theme.card)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Theme.border),
                alignment: .bottom
            )

            // Page dots indicator
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Theme.accent : Theme.border)
                        .frame(width: index == currentPage ? 8 : 6,
                               height: index == currentPage ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.vertical, 8)
            .background(Theme.surface)

            // Swipeable canvas pages
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    CanvasView(canvasView: page.canvas, toolPicker: toolPicker)
                        .tag(index)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.white)   // override TabView's default black background
            .ignoresSafeArea(edges: .bottom)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: currentPage) { _, newPage in
            pages[newPage].canvas.becomeFirstResponder()
        }
        .alert("Saved!", isPresented: $showSaveConfirmation) {
            Button("OK") {}
        } message: {
            Text("Page \(currentPage + 1) saved to your lesson gallery.")
        }
        .sheet(isPresented: $showGallery) {
            DrawingGalleryView(bookingId: booking.id)
        }
        .sheet(isPresented: $showAISheet) {
            AIExplanationSheet(
                isLoading: isAILoading,
                explanation: aiExplanation,
                errorMessage: aiErrorMessage
            )
        }
    }

    private func addPage() {
        let newPage = CanvasPage()
        pages.append(newPage)
        currentPage = pages.count - 1
    }

    private func explainWithAI() {
        let canvas = pages[currentPage].canvas

        // Guard: nothing to explain if the page is blank
        guard !canvas.drawing.strokes.isEmpty else {
            aiExplanation = nil
            aiErrorMessage = "Nothing to explain yet — draw something on this page first."
            showAISheet = true
            return
        }

        // Reset state and open the sheet immediately so the user sees the
        // loading spinner straight away rather than waiting in silence.
        aiExplanation = nil
        aiErrorMessage = nil
        isAILoading = true
        showAISheet = true

        Task {
            // Crop the capture to where the user actually drew (with padding),
            // rather than sending the entire blank canvas.
            // PKDrawing.bounds gives the tight bounding box of all strokes.
            // We expand it 80pt on each side so nothing is clipped at the edges.
            let strokeBounds = canvas.drawing.bounds
            let fallback = canvas.bounds.isEmpty
                ? CGRect(x: 0, y: 0, width: 1024, height: 768)
                : canvas.bounds
            let captureBounds = strokeBounds.isNull || strokeBounds.isEmpty
                ? fallback
                : strokeBounds.insetBy(dx: -80, dy: -80)
            // UIScreen.main.scale (2× or 3×) gives a sharper image — important
            // for GPT-4o to read handwriting clearly.
            let image = canvas.drawing.image(from: captureBounds, scale: UIScreen.main.scale)

            do {
                aiExplanation = try await AIService().explain(image: image)
            } catch {
                aiErrorMessage = error.localizedDescription
            }
            isAILoading = false
        }
    }

    private func savePage() {
        // Save as PKDrawing binary data (.pkdrawing) so the drawing can be
        // reloaded into a PKCanvasView later and remain fully editable.
        // PNG would be a flat image — you can't put it back on a canvas.
        let drawing = pages[currentPage].canvas.drawing
        let data = drawing.dataRepresentation()
        let filename = "lesson_\(booking.id)_p\(currentPage + 1)_\(Int(Date().timeIntervalSince1970)).pkdrawing"
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? data.write(to: dir.appendingPathComponent(filename))
        showSaveConfirmation = true
    }
}

// MARK: - Canvas UIViewRepresentable

struct CanvasView: UIViewRepresentable {
    let canvasView: PKCanvasView
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

// MARK: - Drawing Gallery

struct DrawingGalleryView: View {
    let bookingId: Int
    @State private var drawings: [URL] = []
    @State private var selectedURL: IdentifiableURL?
    @State private var refreshToken = UUID()
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 16)]

    var body: some View {
        NavigationStack {
            Group {
                if drawings.isEmpty {
                    ContentUnavailableView(
                        "No saved drawings",
                        systemImage: "pencil.slash",
                        description: Text("Tap \"Save Page\" on the whiteboard to save drawings here.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(drawings, id: \.self) { url in
                                DrawingThumbnailView(url: url, refreshToken: refreshToken)
                                    .onTapGesture {
                                        selectedURL = IdentifiableURL(url: url)
                                    }
                            }
                        }
                        .padding()
                    }
                    .background(Theme.bg)
                }
            }
            .navigationTitle("Saved Drawings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .onAppear { loadDrawings() }
        // When the editor closes (selectedURL becomes nil), refresh thumbnails
        // in case the drawing was modified.
        .onChange(of: selectedURL) { _, newValue in
            if newValue == nil { refreshToken = UUID() }
        }
        .fullScreenCover(item: $selectedURL) { item in
            EditableDrawingView(drawingURL: item.url)
        }
    }

    private func loadDrawings() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }
        drawings = files
            .filter {
                $0.lastPathComponent.hasPrefix("lesson_\(bookingId)_") &&
                $0.pathExtension == "pkdrawing"
            }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
}

// MARK: - Drawing Thumbnail

struct DrawingThumbnailView: View {
    let url: URL
    let refreshToken: UUID     // changing this forces the thumbnail to re-render
    @State private var thumbnail: UIImage?

    // A standard landscape canvas size used as the coordinate space for rendering.
    // Strokes are stored in absolute points — this rect determines how much of
    // the canvas is captured in the thumbnail image.
    private static let canvasBounds = CGRect(x: 0, y: 0, width: 1024, height: 768)

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: Theme.radiusMd)
                    .fill(Theme.surface)
                    .aspectRatio(4/3, contentMode: .fit)
                    .overlay(ProgressView().tint(Theme.accent))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd)
                .stroke(Theme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        // .task(id:) re-runs whenever `refreshToken` changes, so thumbnails
        // automatically update after the user edits a drawing.
        .task(id: refreshToken) { await renderThumbnail() }
    }

    @MainActor
    private func renderThumbnail() async {
        guard let data = try? Data(contentsOf: url),
              let drawing = try? PKDrawing(data: data) else { return }
        thumbnail = drawing.image(from: Self.canvasBounds, scale: 1.0)
    }
}

// MARK: - Editable Drawing View

struct EditableDrawingView: View {
    let drawingURL: URL

    @Environment(\.dismiss) private var dismiss
    @State private var page = CanvasPage()
    @State private var toolPicker = PKToolPicker()

    var body: some View {
        ZStack(alignment: .top) {

            // Full-screen editable canvas
            CanvasView(canvasView: page.canvas, toolPicker: toolPicker)
                .ignoresSafeArea()

            // Floating header bar
            HStack {
                Button {
                    saveAndDismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("Save & Close")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
                }

                Spacer()

                Button {
                    dismiss()   // close without saving changes
                } label: {
                    Text("Discard changes")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding()
            .background(Theme.card.opacity(0.95))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Theme.border),
                alignment: .bottom
            )
        }
        .onAppear { loadDrawing() }
    }

    private func loadDrawing() {
        guard let data = try? Data(contentsOf: drawingURL),
              let drawing = try? PKDrawing(data: data) else { return }
        page.canvas.drawing = drawing
    }

    private func saveAndDismiss() {
        // Overwrite the same .pkdrawing file with the current state of the canvas.
        let data = page.canvas.drawing.dataRepresentation()
        try? data.write(to: drawingURL)
        dismiss()
    }
}

// MARK: - AI Explanation Sheet

struct AIExplanationSheet: View {
    let isLoading: Bool
    let explanation: String?
    let errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if isLoading {
                        // Shown immediately while waiting for the API response
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                                .tint(Color(hex: "7C3AED"))
                            Text("Reading your notes…")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)

                    } else if let error = errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)

                    } else if let text = explanation {
                        // AI label
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color(hex: "7C3AED"))
                            Text("AI Explanation")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                        }

                        // The actual explanation text
                        Text(text)
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(24)
            }
            .background(Theme.bg)
            .navigationTitle("Explain with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        // .presentationDetents lets the sheet snap to half-screen or full-screen.
        // The user can drag it up for more room to read a long explanation.
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Helpers

struct IdentifiableURL: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}
