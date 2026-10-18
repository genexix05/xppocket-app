import SwiftUI
import UniformTypeIdentifiers

/// File importer + alerts for installing `.zip` layout packs locally.
struct LayoutPackImportSupport: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var errorMessage: String?
    @Binding var successMessage: String?

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: $isPresented,
                allowedContentTypes: LayoutPackInstaller.packTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    Task { @MainActor in
                        do {
                            let install = try LayoutPackInstaller.installLocalFile(url)
                            successMessage =
                                install.updated
                                ? String(localized: "Updated profile “\(install.profileName)”.")
                                : String(localized: "Added profile “\(install.profileName)”.")
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .alert("Could not import", isPresented: errorPresented) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Imported", isPresented: successPresented) {
                Button("OK", role: .cancel) { successMessage = nil }
            } message: {
                Text(successMessage ?? "")
            }
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var successPresented: Binding<Bool> {
        Binding(get: { successMessage != nil }, set: { if !$0 { successMessage = nil } })
    }
}

extension View {
    func layoutPackImport(
        isPresented: Binding<Bool>,
        errorMessage: Binding<String?>,
        successMessage: Binding<String?>
    ) -> some View {
        modifier(
            LayoutPackImportSupport(
                isPresented: isPresented,
                errorMessage: errorMessage,
                successMessage: successMessage))
    }
}
