import SwiftUI
import PhotosUI

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ScanViewModel()
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: KiwiSpacing.xl) {
            Spacer()

            Image(systemName: "refrigerator.fill")
                .font(.system(size: 72))
                .foregroundStyle(.kiwiGreen)
                .accessibilityHidden(true)

            Text("Scan Your Fridge")
                .font(KiwiTypography.largeTitle)
                .fontWeight(.bold)

            Text("Take a photo of your fridge and we'll suggest recipes based on what you have.")
                .font(KiwiTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KiwiSpacing.xxl)

            quotaBadge

            Spacer()

            VStack(spacing: KiwiSpacing.md) {
                PrimaryButton("Take Photo") {
                    viewModel.showCamera = true
                }
                .disabled(!viewModel.canScan)

                PhotosPicker(
                    selection: $photosPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Choose from Library")
                        .font(KiwiTypography.headline)
                        .foregroundStyle(.kiwiGreen)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .padding(.horizontal, KiwiSpacing.xl)
                        .padding(.vertical, KiwiSpacing.md)
                }
                .disabled(!viewModel.canScan)
            }
            .padding(.bottom, KiwiSpacing.xxl)
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .task { await viewModel.loadQuota() }
        .fullScreenCover(isPresented: $viewModel.showCamera) {
            ImagePicker { image in
                viewModel.selectImage(image)
            }
        }
        .onChange(of: photosPickerItem) {
            Task {
                if let data = try? await photosPickerItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectImage(image)
                }
            }
        }
        .navigationDestination(item: $viewModel.selectedImage) { identifiableImage in
            ResultsView(image: identifiableImage.image)
        }
    }

    @ViewBuilder
    private var quotaBadge: some View {
        if viewModel.isLoadingQuota {
            ProgressView()
        } else if viewModel.canScan {
            Label("\(viewModel.remainingScans) scans left today", systemImage: "camera.fill")
                .font(KiwiTypography.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Label("You've used all your scans for today. Come back tomorrow!", systemImage: "clock")
                .font(KiwiTypography.subheadline)
                .foregroundStyle(.kiwiOrange)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KiwiSpacing.xl)
        }
    }
}

/// Lightweight wrapper so UIImage can be used with navigationDestination(item:).
struct IdentifiableImage: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage

    static func == (lhs: IdentifiableImage, rhs: IdentifiableImage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    NavigationStack {
        ScanView()
    }
}
