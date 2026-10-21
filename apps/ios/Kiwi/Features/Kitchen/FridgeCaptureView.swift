import SwiftUI
import PhotosUI
import AVFoundation

struct FridgeCaptureView: View {
    @Environment(KitchenStore.self) private var kitchen
    @Environment(\.dismiss) private var dismiss
    @State private var photos: [IdentifiableImage] = []
    @State private var selection: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var permissionDenied = false
    @State private var working = false
    @State private var loadingPhotos = false
    @State private var review: [FridgeItem] = []
    @State private var isReviewing = false
    @State private var message: String?
    @State private var workTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                KitchenHeading(eyebrow: isReviewing ? "Make it yours" : "Stock your kitchen", title: isReviewing ? "Did we get it right?" : "What's in\nyour fridge?", subtitle: isReviewing ? "Correct anything we missed. These ingredients will merge with your saved fridge." : "Photograph a shelf, a drawer, or the door. Add up to three photos for a fuller picture.")
                if isReviewing {
                    reviewList
                } else {
                    photoList
                    if let quota = kitchen.quota {
                        Text("\(quota.remaining) scans left today · one batch counts as one scan")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Only the photos you choose are uploaded. Location metadata is removed, and Kiwi doesn't store the photos after processing.")
                        .font(.footnote).foregroundStyle(.secondary)
                    KitchenAction(title: working ? "Looking for ingredients…" : "Identify ingredients", icon: "viewfinder", busy: working) { identify() }
                        .disabled(photos.isEmpty || kitchen.quota?.remaining == 0 || loadingPhotos)
                }
                if let message { Text(message).font(.subheadline).foregroundStyle(.secondary).accessibilityIdentifier("captureMessage") }
            }.padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isReviewing ? "Review ingredients" : "Add photos").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(working ? "Cancel request" : "Close") { workTask?.cancel(); dismiss() }
            }
        }
        .interactiveDismissDisabled(working)
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker { image in
                if photos.count < 3 { photos.append(IdentifiableImage(image: image)) }
                showCamera = false
            }.ignoresSafeArea()
        }
        .onChange(of: selection) { _, items in
            guard !items.isEmpty else { return }
            loadingPhotos = true
            workTask = Task {
                defer { loadingPhotos = false; selection = [] }
                do {
                    for item in items {
                        try Task.checkCancellation()
                        guard photos.count < 3 else { break }
                        guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                            message = "One photo couldn't be opened. Try selecting it again."; continue
                        }
                        photos.append(IdentifiableImage(image: image))
                    }
                } catch { if !(error is CancellationError) { message = "Couldn't open those photos. Please try again." } }
            }
        }
        .alert("Camera access", isPresented: $permissionDenied) {
            Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Allow camera access in Settings, or choose photos from your library.") }
        .onDisappear { workTask?.cancel() }
    }
    private var photoList: some View {
        VStack(spacing: 16) {
            if photos.isEmpty {
                Image(systemName: "refrigerator").font(.largeTitle).foregroundStyle(.kitchenGreen)
                    .frame(maxWidth: .infinity, minHeight: 140).kitchenSurface().accessibilityHidden(true)
            }
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                HStack(spacing: 16) {
                    Image(uiImage: photo.image).resizable().scaledToFill().frame(width: 76, height: 86).clipped().clipShape(RoundedRectangle(cornerRadius: 14)).accessibilityLabel("Fridge photo \(index + 1)")
                    Text("Photo \(index + 1)").font(.headline)
                    Spacer()
                    Button { photos.removeAll { $0.id == photo.id } } label: { Image(systemName: "xmark.circle.fill").frame(width: 44, height: 44) }.accessibilityLabel("Remove photo \(index + 1)")
                }.kitchenSurface()
            }
            if photos.count < 3 {
                HStack {
                    Button { Task { await openCamera() } } label: { Label("Camera", systemImage: "camera").frame(maxWidth: .infinity, minHeight: 48) }
                    PhotosPicker(selection: $selection, maxSelectionCount: max(1, 3 - photos.count), matching: .images) {
                        Label("Library", systemImage: "photo").frame(maxWidth: .infinity, minHeight: 48)
                    }
                }.buttonStyle(.bordered).disabled(working || loadingPhotos)
            }
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--kitchen-ui-tests"), photos.count < 3 {
                Button("Load test photo") {
                    let image = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120)).image { context in
                        UIColor.systemGreen.setFill(); context.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
                    }
                    photos.append(IdentifiableImage(image: image))
                }
            }
#endif
            if loadingPhotos { ProgressView("Opening photos…") }
        }.disabled(working)
    }
    private var reviewList: some View {
        VStack(spacing: 12) {
            ForEach($review) { $item in
                HStack {
                    TextField("Ingredient", text: $item.name).frame(minHeight: 44)
                    Button { review.removeAll { $0.id == item.id } } label: { Image(systemName: "minus.circle").frame(width: 44, height: 44) }.accessibilityLabel("Remove \(item.name)")
                }.kitchenSurface()
            }
            Button { review.append(FridgeItem(name: "")) } label: { Label("Add a missed ingredient", systemImage: "plus").frame(minHeight: 44) }
            KitchenAction(title: working ? "Saving…" : "Save to my fridge", icon: "checkmark", busy: working) {
                working = true
                workTask = Task {
                    if await kitchen.saveInventory(review) { photos = []; dismiss() }
                    working = false
                }
            }.disabled(review.isEmpty || review.contains { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.name.count > 100 })
            Button("Back to photos") { isReviewing = false }.frame(minHeight: 44).disabled(working)
        }
    }
    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { message = "Camera isn't available here. Choose photos from your library."; return }
        let allowed: Bool
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            allowed = await AVCaptureDevice.requestAccess(for: .video)
        } else { allowed = AVCaptureDevice.authorizationStatus(for: .video) == .authorized }
        if allowed { showCamera = true } else { permissionDenied = true }
    }
    private func identify() {
        working = true; message = nil
        workTask = Task {
            defer { working = false }
            do {
                var payload: [Data] = []
                for photo in photos {
                    try Task.checkCancellation()
                    payload.append(try await Self.prepare(photo.image))
                }
                review = try await kitchen.recognize(payload)
                try Task.checkCancellation()
                if review.isEmpty { message = "No ingredients found. Try a clearer photo, or add ingredients by hand in your fridge." }
                else { isReviewing = true }
            } catch { if !(error is CancellationError) { message = "Couldn't identify ingredients. Your photos are still here—try again." } }
        }
    }
    @concurrent private static func prepare(_ image: UIImage) async throws -> Data {
        // Normalize camera orientation before metadata is removed.
        let size = image.size
        let scale = min(1, 1920 / max(size.width, size.height))
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size.width * scale, height: size.height * scale), format: format)
        let normalized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: CGSize(width: size.width * scale, height: size.height * scale))) }
        return try ImageMetadataStripper().strip(image: normalized)
    }
}
