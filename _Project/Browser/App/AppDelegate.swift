//
//  AppDelegate.swift
//  AeroTV
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let settings = BrowserSettings.shared

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        settings.configureUserAgent()
        restoreCookies()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        saveCookies()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveCookies()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        restoreCookies()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        restoreCookies()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveCookies()
    }

    // MARK: - Cookie Persistence

    private let cookieKey = "ApplicationCookie"

    private func saveCookies() {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return }

        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: cookies,
                requiringSecureCoding: false
            )
            UserDefaults.standard.set(data, forKey: cookieKey)
        } catch {
            print("⚠️ Failed to save cookies: \(error)")
        }
    }

    private func restoreCookies() {
        guard let data = UserDefaults.standard.data(forKey: cookieKey) else { return }

        do {
            if let cookies = try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NSHTTPCookie.self],
                from: data
            ) as? [HTTPCookie] {
                cookies.forEach { HTTPCookieStorage.shared.setCookie($0) }
            }
        } catch {
            // Fallback to deprecated method for legacy data
            if let cookies = NSKeyedUnarchiver.unarchiveObject(with: data) as? [HTTPCookie] {
                cookies.forEach { HTTPCookieStorage.shared.setCookie($0) }
            }
        }
    }
}
