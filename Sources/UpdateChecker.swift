import Foundation
import SwiftUI

/// A release as GitHub's API describes it.
struct GitHubRelease: Identifiable, Decodable {
    let tagName: String
    let body: String?
    let htmlURL: URL
    let assets: [Asset]

    struct Asset: Decodable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case htmlURL = "html_url"
        case assets
    }

    var id: String { tagName }
    var version: String { tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName }
    var diskImage: URL? { assets.first { $0.name.hasSuffix(".dmg") }?.browserDownloadURL }
}

/// Asks GitHub whether a newer release exists. It never installs anything: the
/// download is a deliberate click, and the app is replaced by hand.
@MainActor
final class UpdateChecker: ObservableObject {

    @Published var pending: GitHubRelease?
    @Published var isChecking = false
    @Published var isUpToDate = false
    @Published var failure: String?

    private let feed = URL(string: "https://api.github.com/repos/FraCata00/Penumbra/releases/latest")!
    private let lastCheckKey = "lastUpdateCheck"
    private let skippedVersionKey = "skippedVersion"

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    /// Once a day is plenty for a wallpaper app, and it keeps the launch quiet.
    func checkOnLaunch() async {
        let last = UserDefaults.standard.object(forKey: lastCheckKey) as? Date
        if let last, Date().timeIntervalSince(last) < 86_400 { return }
        await check(userInitiated: false)
    }

    func check(userInitiated: Bool) async {
        isChecking = true
        failure = nil
        isUpToDate = false
        defer { isChecking = false }

        do {
            var request = URLRequest(url: feed)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("Penumbra/\(currentVersion)", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard status == 200 else {
                throw WallpaperError(message: "GitHub answered \(status).")
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            UserDefaults.standard.set(Date(), forKey: lastCheckKey)

            guard isNewer(release.version, than: currentVersion) else {
                isUpToDate = userInitiated
                return
            }
            // A version the user skipped stays hidden until they ask explicitly.
            if userInitiated || release.version != UserDefaults.standard.string(forKey: skippedVersionKey) {
                pending = release
            }
        } catch {
            // Nobody asked, so nobody hears about it.
            failure = userInitiated ? error.localizedDescription : nil
        }
    }

    func skip(_ release: GitHubRelease) {
        UserDefaults.standard.set(release.version, forKey: skippedVersionKey)
        pending = nil
    }

    /// Compares dotted numeric versions, so 1.10.0 beats 1.9.9.
    func isNewer(_ candidate: String, than current: String) -> Bool {
        let lhs = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let rhs = current.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(lhs.count, rhs.count) {
            let l = i < lhs.count ? lhs[i] : 0
            let r = i < rhs.count ? rhs[i] : 0
            if l != r { return l > r }
        }
        return false
    }
}
