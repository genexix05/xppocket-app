import Foundation

/// Persists the community upload admin key on device (Settings → upload form).
enum CommunityAdminCredentials {
    private static let key = "communityLayouts.adminKey"

    static var adminKey: String {
        get { UserDefaults.standard.string(forKey: key) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
