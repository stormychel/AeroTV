//
//  BrowserSettings.swift
//  AeroTV
//

import Foundation
import SwiftUI

final class BrowserSettings: ObservableObject {
    static let shared = BrowserSettings()

    // MARK: - User Agent Strings

    static let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    static let mobileUserAgent = "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    // MARK: - Settings

    @AppStorage("homepage") var homepage: String = "https://www.google.com"
    @AppStorage("MobileMode") var isMobileMode: Bool = false
    @AppStorage("ScalePagesToFit") var scalesPagesToFit: Bool = false
    @AppStorage("TextFontSize") private var textFontSizeRaw: Int = 100
    @AppStorage("ShowTopNavigationBar") var showTopNavigationBar: Bool = true
    @AppStorage("DontShowHintsOnLaunch") var dontShowHintsOnLaunch: Bool = false
    @AppStorage("savedURLtoReopen") var savedURLToReopen: String?

    // MARK: - Font Size (validated 50-200)

    var textFontSize: Int {
        get { min(200, max(50, textFontSizeRaw)) }
        set { textFontSizeRaw = min(200, max(50, newValue)) }
    }

    func increaseFontSize() {
        textFontSize += 5
    }

    func decreaseFontSize() {
        textFontSize -= 5
    }

    // MARK: - User Agent

    var userAgent: String {
        isMobileMode ? Self.mobileUserAgent : Self.desktopUserAgent
    }

    func configureUserAgent() {
        UserDefaults.standard.register(defaults: ["UserAgent": userAgent])
    }

    func toggleMobileMode() {
        isMobileMode.toggle()
        configureUserAgent()
    }
}
