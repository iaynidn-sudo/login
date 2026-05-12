import Foundation
import WebKit

class FirebasePlugin: PluginInterface {
    var name: String = "Firebase"

    static func register() {
        PluginManager.shared.registerPlugin(FirebasePlugin())
    }

    func showTestNotification() {
        print("FirebasePlugin: Notifications disabled (stub)")
    }
}
