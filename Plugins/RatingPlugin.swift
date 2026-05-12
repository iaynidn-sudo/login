import Foundation
import WebKit
import StoreKit

class RatingPlugin: PluginInterface {
    var name: String = "Rating"
    private weak var webView: WKWebView?
    
    static func register() {
        PluginManager.shared.registerPlugin(RatingPlugin())
    }
    
    func initialize(context: SWVContext, webView: WKWebView) {
        self.webView = webView
    }
    
    func webViewDidFinishLoad(url: URL) {
        let script = """
            if (!window.Rating) {
                window.Rating = {
                    request: function() {
                        if (window.webkit && window.webkit.messageHandlers.rating) {
                            window.webkit.messageHandlers.rating.postMessage('request');
                        }
                    },
                    canRate: function(callback) {
                        if (window.webkit && window.webkit.messageHandlers.rating) {
                            window._ratingCallback = callback;
                            window.webkit.messageHandlers.rating.postMessage('canRate');
                        }
                    }
                };
                console.log('Rating JavaScript interface injected.');
            }
        """
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    func handleScriptMessage(message: WKScriptMessage) {
        guard message.name == "rating", let body = message.body as? String else { return }
        
        if body == "request" {
            requestRating()
        } else if body == "canRate" {
            checkCanRate()
        }
    }
    
    private func requestRating() {
        if #available(iOS 14.0, *) {
            SKStoreReviewController.requestReview()
        } else {
            guard let url = URL(string: "https://apps.apple.com/app/id" + appBundleID()) else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func checkCanRate() {
        let canRate = SKStoreReviewController.isAvailable
        let script = "if (window._ratingCallback) { window._ratingCallback(\(canRate)); window._ratingCallback = null; }"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    private func appBundleID() -> String {
        return Bundle.main.bundleIdentifier ?? ""
    }
}