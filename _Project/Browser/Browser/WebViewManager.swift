//
//  WebViewManager.swift
//  AeroTV
//
//  Wraps UIWebView private API access for tvOS
//

import UIKit

final class WebViewManager: NSObject {

    // MARK: - Properties

    /// The UIWebView instance (private API)
    private(set) var webView: UIView?

    /// Delegate for webview events
    weak var delegate: WebViewManagerDelegate?

    // MARK: - Computed Properties

    var scrollView: UIScrollView? {
        webView?.value(forKey: "scrollView") as? UIScrollView
    }

    var request: URLRequest? {
        webView?.value(forKey: "request") as? URLRequest
    }

    var currentURL: String? {
        request?.url?.absoluteString
    }

    var canGoBack: Bool {
        (webView?.value(forKey: "canGoBack") as? Bool) ?? false
    }

    var canGoForward: Bool {
        (webView?.value(forKey: "canGoForward") as? Bool) ?? false
    }

    var scalesPageToFit: Bool {
        get { (webView?.value(forKey: "scalesPageToFit") as? Bool) ?? false }
        set { webView?.setValue(newValue, forKey: "scalesPageToFit") }
    }

    // MARK: - Initialization

    func createWebView() -> UIView? {
        guard let webViewClass = NSClassFromString("UIWebView") as? UIView.Type else {
            print("⚠️ UIWebView not available")
            return nil
        }

        let view = webViewClass.init()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false

        // Set delegate
        webView = view
        setDelegate(self)

        return view
    }

    private func setDelegate(_ delegate: AnyObject) {
        webView?.perform(Selector(("setDelegate:")), with: delegate)
    }

    // MARK: - Navigation

    func loadRequest(_ request: URLRequest) {
        _ = webView?.perform(Selector(("loadRequest:")), with: request)
    }

    func loadURL(_ urlString: String) {
        var urlToLoad = urlString

        // Add http:// if no scheme
        if !urlToLoad.contains("://") {
            urlToLoad = "http://\(urlToLoad)"
        }

        guard let url = URL(string: urlToLoad) else { return }
        loadRequest(URLRequest(url: url))
    }

    func reload() {
        _ = webView?.perform(Selector(("reload")))
    }

    func goBack() {
        _ = webView?.perform(Selector(("goBack")))
    }

    func goForward() {
        _ = webView?.perform(Selector(("goForward")))
    }

    func stopLoading() {
        _ = webView?.perform(Selector(("stopLoading")))
    }

    // MARK: - JavaScript

    func evaluateJavaScript(_ script: String) -> String? {
        let selector = Selector(("stringByEvaluatingJavaScriptFromString:"))
        guard let result = webView?.perform(selector, with: script) else { return nil }
        return result.takeUnretainedValue() as? String
    }

    func getDocumentTitle() -> String {
        evaluateJavaScript("document.title") ?? ""
    }

    func getElementType(at point: CGPoint) -> String? {
        let js = "document.elementFromPoint(\(Int(point.x)), \(Int(point.y))).type;"
        return evaluateJavaScript(js)?.lowercased()
    }

    func getElementAttribute(_ attribute: String, at point: CGPoint) -> String? {
        let js = "document.elementFromPoint(\(Int(point.x)), \(Int(point.y))).\(attribute);"
        return evaluateJavaScript(js)
    }

    func clickElement(at point: CGPoint) {
        let js = "document.elementFromPoint(\(Int(point.x)), \(Int(point.y))).click()"
        _ = evaluateJavaScript(js)
    }

    func setInputValue(_ value: String, at point: CGPoint, submit: Bool = false) {
        let escapedValue = value.replacingOccurrences(of: "'", with: "\\'")
        var js = """
            var textField = document.elementFromPoint(\(Int(point.x)), \(Int(point.y)));
            textField.value = '\(escapedValue)';
            """
        if submit {
            js += "textField.form.submit();"
        }
        _ = evaluateJavaScript(js)
    }

    func hasFormSubmit(at point: CGPoint) -> Bool {
        let js = "document.elementFromPoint(\(Int(point.x)), \(Int(point.y))).form.hasAttribute('onsubmit');"
        return evaluateJavaScript(js) == "true"
    }

    func isClickableElement(at point: CGPoint) -> Bool {
        let js = "document.elementFromPoint(\(Int(point.x)), \(Int(point.y))).closest('a, input') !== null"
        return evaluateJavaScript(js) == "true"
    }

    func updateFontSize(_ percentage: Int) {
        let js = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '\(percentage)%'"
        _ = evaluateJavaScript(js)
    }

    // MARK: - Window Dimensions

    func getDisplayWidth() -> Int {
        Int(evaluateJavaScript("window.innerWidth") ?? "0") ?? 0
    }
}

// MARK: - UIWebViewDelegate Methods

extension WebViewManager {

    @objc func webViewDidStartLoad(_ webView: AnyObject) {
        delegate?.webViewDidStartLoad()
    }

    @objc func webViewDidFinishLoad(_ webView: AnyObject) {
        let title = getDocumentTitle()
        let url = currentURL ?? ""
        delegate?.webViewDidFinishLoad(title: title, url: url)
    }

    @objc func webView(_ webView: AnyObject, didFailLoadWithError error: Error) {
        delegate?.webViewDidFailLoad(error: error)
    }

    @objc func webView(_ webView: AnyObject, shouldStartLoadWith request: URLRequest, navigationType: Int) -> Bool {
        return delegate?.webViewShouldStartLoad(with: request) ?? true
    }
}

// MARK: - Delegate Protocol

protocol WebViewManagerDelegate: AnyObject {
    func webViewDidStartLoad()
    func webViewDidFinishLoad(title: String, url: String)
    func webViewDidFailLoad(error: Error)
    func webViewShouldStartLoad(with request: URLRequest) -> Bool
}

extension WebViewManagerDelegate {
    func webViewShouldStartLoad(with request: URLRequest) -> Bool { true }
}
