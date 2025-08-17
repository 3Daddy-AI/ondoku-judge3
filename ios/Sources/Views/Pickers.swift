import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

// MARK: - Camera (UIImagePickerController)
struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void
        init(onImage: @escaping (UIImage) -> Void) { self.onImage = onImage }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage { onImage(img) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

// MARK: - Photos (PhotosPicker)
@available(iOS 16.0, *)
struct PhotoLibraryPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: PhotosPickerItem? = nil
    var onImage: (UIImage) -> Void

    var body: some View {
        VStack(spacing: 12) {
            PhotosPicker("写真をえらぶ", selection: $selection, matching: .images)
            Button("とじる") { dismiss() }
        }
        .padding()
        .onChange(of: selection) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    onImage(img)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - PDF (UIDocumentPickerViewController)
struct PDFPicker: UIViewControllerRepresentable {
    var onURL: (URL) -> Void
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types = [UTType.pdf]
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: types)
        vc.allowsMultipleSelection = false
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onURL: onURL) }
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onURL: (URL) -> Void
        init(onURL: @escaping (URL) -> Void) { self.onURL = onURL }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { onURL(url) }
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

