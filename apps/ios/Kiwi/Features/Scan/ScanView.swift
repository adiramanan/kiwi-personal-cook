import SwiftUI
import PhotosUI

struct ScanView: View {
    @Bindable var viewModel: ScanViewModel
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var navigateToResults = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Hero section
                VStack(spacing: 16) {
                    Image(systemName: "refrigerator")
                        .font(.system(size: 72))
                        .foregroundStyle(.kiwiGreen)
                        .accessibilityLabel("Refrigerator icon")

                    Text("Scan Your Fridge")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Take a photo of your fridge and we'll suggest quick, easy recipes with what you have.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Quota indicator
                VStack(spacing: 24) {
                    if viewModel.isLoadingQuota {
                        ProgressView()
                    } else if !viewModel.canScan {
                        Text("You've used all your scans for today. Come back tomorrow!")
                            .font(.callout)
                            .foregroundStyle(.kiwiOrange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else {
                        Text("\(viewModel.remainingScans) scans left today")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        PrimaryButton("Take Photo", icon: "camera", isDisabled: !viewModel.canScan) {
                            showCamera = true
                        }
                        .accessibilityHint("Opens camera to photograph your fridge")

                        PrimaryButton("Choose from Library", icon: "photo.on.rectangle", isDisabled: !viewModel.canScan) {
                            showPhotoPicker = true
                        }
                        .accessibilityHint("Opens photo library to select a fridge photo")
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
                    .frame(height: 40)
            }
            .navigationTitle("Kiwi")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadQuota()
            }
            .fullScreenCover(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $viewModel.selectedImage)
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photosPickerItem, matching: .images)
            .onChange(of: photosPickerItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectImage(image)
                    }
                }
            }
            .onChange(of: viewModel.selectedImage) { _, newImage in
                if newImage != nil {
                    navigateToResults = true
                }
            }
            .navigationDestination(isPresented: $navigateToResults) {
                if let image = viewModel.selectedImage {
                    ResultsView(viewModel: ResultsViewModel(
                        image: image,
                        scanFridgeUseCase: ScanFridgeUseCase(
                            apiClient: AppDependencies.shared.apiClient
                        )
                    ))
                }
            }
        }
    }
}
