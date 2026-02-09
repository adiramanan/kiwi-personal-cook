import PhotosUI
import SwiftUI

struct ScanView: View {
    @State private var viewModel = ScanViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var showResults = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Scan Your Fridge")
                    .font(.largeTitle)
                if let quota = viewModel.quota {
                    Text("\(quota.remaining) scans left today")
                        .font(.kiwiBody)
                } else if viewModel.isLoadingQuota {
                    ProgressView()
                }
                PrimaryButton(title: "Take Photo") {
                    showCamera = true
                }
                .disabled(isQuotaZero)
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Choose from Library")
                        .font(.kiwiHeadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.kiwiAccent.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isQuotaZero)
                if isQuotaZero {
                    Text("You've used all your scans for today. Come back tomorrow!")
                        .font(.kiwiBody)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showResults) {
                if let image = selectedImage {
                    ResultsView(image: image)
                }
            }
            .task {
                await viewModel.loadQuota()
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker { image in
                    selectedImage = image
                    showResults = true
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        showResults = true
                    }
                }
            }
        }
    }

    private var isQuotaZero: Bool {
        viewModel.quota?.remaining == 0
    }
}
