import Foundation
import WebKit
import CoreLocation

class LocationPlugin: NSObject, PluginInterface, CLLocationManagerDelegate {
    var name: String = "Location"
    private weak var webView: WKWebView?
    private var locationManager: CLLocationManager?
    
    static func register() {
        PluginManager.shared.registerPlugin(LocationPlugin())
    }
    
    func initialize(context: SWVContext, webView: WKWebView) {
        self.webView = webView
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func webViewDidFinishLoad(url: URL) {
        let script = """
            if (!window.SWVLocation) {
                window.SWVLocation = {
                    getCurrentPosition: function(callback) {
                        if (window.webkit && window.webkit.messageHandlers.location) {
                            window._locationCallback = callback;
                            window.webkit.messageHandlers.location.postMessage('getCurrentPosition');
                        }
                    }
                };
                console.log('Location JavaScript interface injected.');
            }
        """
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    func handleScriptMessage(message: WKScriptMessage) {
        guard message.name == "location", let body = message.body as? String else { return }
        
        if body == "getCurrentPosition" {
            getCurrentPosition()
        }
    }
    
    func requestInitialPermission() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
    private func getCurrentPosition() {
        let status = CLLocationManager.authorizationStatus()
        
        if status == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
            return
        }
        
        if status == .denied || status == .restricted {
            sendLocationError(error: "Location permission denied")
            return
        }
        
        locationManager?.requestLocation()
    }
    
    private func sendLocationError(error: String) {
        let script = "if (window._locationCallback) { window._locationCallback(null, null, '\(error)'); window._locationCallback = null; }"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    private func sendLocationUpdate(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let script = "if (window._locationCallback) { window._locationCallback(\(latitude), \(longitude), null); window._locationCallback = null; }"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            sendLocationUpdate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        sendLocationError(error: error.localizedDescription)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = CLLocationManager.authorizationStatus()
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            sendLocationError(error: "Location permission denied")
        }
    }
}