import Foundation
import WebKit
import UIKit

class DialogPlugin: PluginInterface {
    var name: String = "Dialog"
    private weak var webView: WKWebView?
    
    static func register() {
        PluginManager.shared.registerPlugin(DialogPlugin())
    }
    
    func initialize(context: SWVContext, webView: WKWebView) {
        self.webView = webView
    }
    
    func webViewDidFinishLoad(url: URL) {
        let script = """
            if (!window.Dialog) {
                window.Dialog = {
                    show: function(options, callback) {
                        if (window.webkit && window.webkit.messageHandlers.dialog) {
                            window.webkit.messageHandlers.dialog.postMessage({
                                title: options.title || '',
                                message: options.message || '',
                                positive: options.positive || 'OK',
                                negative: options.negative || null
                            });
                            window._dialogCallback = callback;
                        }
                    }
                };
                console.log('Dialog JavaScript interface injected.');
            }
        """
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    func handleScriptMessage(message: WKScriptMessage) {
        guard message.name == "dialog", let body = message.body as? [String: Any] else { return }
        
        let title = body["title"] as? String ?? ""
        let message = body["message"] as? String ?? ""
        let positive = body["positive"] as? String ?? "OK"
        let negative = body["negative"] as? String
        
        showDialog(title: title, message: message, positiveButton: positive, negativeButton: negative) { result in
            let script = "if (window._dialogCallback) { window._dialogCallback('\(result)'); window._dialogCallback = null; }"
            DispatchQueue.main.async {
                self.webView?.evaluateJavaScript(script, completionHandler: nil)
            }
        }
    }
    
    private func showDialog(title: String, message: String, positiveButton: String, negativeButton: String?, completion: @escaping (String) -> Void) {
        guard let rootVC = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first(where: \.isKeyWindow)?.rootViewController else {
            completion("cancel")
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: positiveButton, style: .default) { _ in
            completion("positive")
        })
        
        if let negative = negativeButton {
            alert.addAction(UIAlertAction(title: negative, style: .cancel) { _ in
                completion("negative")
            })
        }
        
        rootVC.present(alert, animated: true)
    }
}