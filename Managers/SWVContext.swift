import Foundation
import Network // Import the Network framework for connectivity checking.

final class SWVContext {
    // The shared singleton instance, accessible from anywhere in the app.
    static let shared = SWVContext()

    // --- CONFIGURATION PROPERTIES (Loaded from swv.properties) ---
    let debugMode: Bool
    let appURL: String
    let offlineURL: String
    let searchURL: String
    let shareURLSuffix: String
    let externalURLExceptionList: [String]
    let pullToRefreshEnabled: Bool
    let fileUploadsEnabled: Bool
    let multipleUploadsEnabled: Bool
    let openExternalURLs: Bool
    let enabledPlugins: [String]
    let playgroundEnabled: Bool
    let permissionsOnLaunch: [String]
    
    // --- DERIVED & STATE PROPERTIES ---
    let host: String
    var initialURL: URL!

    private init() {
        let config = ConfigLoader()
        
        // --- Load all properties from the config file ---
        self.debugMode = config.getBool(key: "debug.mode", defaultValue: false)
        self.appURL = config.getString(key: "app.url", defaultValue: "https://example.com")
        self.offlineURL = config.getString(key: "offline.url", defaultValue: "offline.html")
        self.searchURL = config.getString(key: "search.url", defaultValue: "https://www.google.com/search?q=")
        self.shareURLSuffix = config.getString(key: "share.url.suffix", defaultValue: "/?share=")
        self.externalURLExceptionList = config.getStringArray(key: "external.url.exception.list", defaultValue: [])
        self.pullToRefreshEnabled = config.getBool(key: "feature.pull.refresh", defaultValue: true)
        self.fileUploadsEnabled = config.getBool(key: "feature.uploads", defaultValue: true)
        self.multipleUploadsEnabled = config.getBool(key: "feature.multiple.uploads", defaultValue: true)
        self.openExternalURLs = config.getBool(key: "feature.open.external.urls", defaultValue: true)
        self.enabledPlugins = config.getStringArray(key: "plugins.enabled", defaultValue: [])
        self.playgroundEnabled = config.getBool(key: "plugins.playground.enabled", defaultValue: true)
        self.permissionsOnLaunch = config.getStringArray(key: "permissions.on.launch", defaultValue: [])
        
        // Extract the host from the main app URL for external link checks.
        self.host = URL(string: appURL)?.host ?? ""
        
        // --- Determine the initial URL to load ---
        // This is a simplified synchronous check. A more advanced version
        // could use NWPathMonitor for real-time updates.
        let isOffline = !isNetworkAvailable()
        
        if isOffline {
            // If offline, attempt to load the local offline file from the app bundle.
            if let offlineFileURL = Bundle.main.url(forResource: self.offlineURL, withExtension: nil, subdirectory: "web") {
                self.initialURL = offlineFileURL
                print("Device is offline. Loading local offline page: \(self.offlineURL)")
            } else {
                // If the offline file doesn't exist, fallback to the main URL (which will likely fail).
                self.initialURL = URL(string: self.appURL)!
                print("Device is offline, but offline page '\(self.offlineURL)' not found in 'Resources/web/'.")
            }
        } else {
            // If online, load the main app URL.
            self.initialURL = URL(string: self.appURL)!
        }
        
        print("SWVContext Initialized. App URL: \(self.appURL). Debug Mode: \(self.debugMode)")
    }
    
    // --- Network Connectivity Check ---
    private func isNetworkAvailable() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var isAvailable = false
        
        monitor.pathUpdateHandler = { path in
            isAvailable = path.status == .satisfied
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
        semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return isAvailable
    }
}
