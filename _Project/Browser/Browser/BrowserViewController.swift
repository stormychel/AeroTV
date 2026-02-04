//
//  BrowserViewController.swift
//  AeroTV
//
//  Main browser view controller - inherits from GCEventViewController for Siri Remote
//

import UIKit
import GameController

class BrowserViewController: GCEventViewController {

    // MARK: - IBOutlets (from Storyboard)

    @IBOutlet weak var topMenuView: UIVisualEffectView!
    @IBOutlet weak var browserContainerView: UIView!
    @IBOutlet weak var btnImageBack: UIImageView!
    @IBOutlet weak var btnImageForward: UIImageView!
    @IBOutlet weak var btnImageRefresh: UIImageView!
    @IBOutlet weak var btnImageHome: UIImageView!
    @IBOutlet weak var btnImageFullScreen: UIImageView!
    @IBOutlet weak var btnImgMenu: UIImageView!
    @IBOutlet weak var lblUrlBar: UILabel!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!

    // MARK: - Managers

    private let webViewManager = WebViewManager()
    private let settings = BrowserSettings.shared
    private let favoritesManager = FavoritesManager.shared
    private let historyManager = HistoryManager.shared
    private lazy var alertPresenter = AlertPresenter(presentingController: self)
    private lazy var cursorController = CursorController()
    private lazy var topNavController = TopNavigationController()
    private lazy var remoteHandler = RemoteInputHandler()

    // MARK: - State

    private var cursorMode = true
    private var previousURL: String = ""
    private var requestURL: String = ""
    private var displayedHintsOnLaunch = false

    /// Public accessor for cursor mode (used by RemoteInputHandler)
    var isInCursorMode: Bool { cursorMode }

    // MARK: - Gesture Recognizers

    private var touchSurfaceDoubleTapRecognizer: UITapGestureRecognizer!
    private var playPauseDoubleTapRecognizer: UITapGestureRecognizer!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true

        setupWebView()
        setupCursor()
        setupGestures()

        loadingSpinner.hidesWhenStopped = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onWebViewDidAppear()
        displayedHintsOnLaunch = true
    }

    // MARK: - Setup

    private func setupWebView() {
        guard let webView = webViewManager.createWebView() else {
            print("⚠️ Failed to create WebView")
            return
        }

        webViewManager.delegate = self

        browserContainerView.addSubview(webView)
        webView.frame = view.bounds

        // Configure scroll view
        if let scrollView = webViewManager.scrollView {
            scrollView.layoutMargins = .zero
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.contentInset = .zero
            scrollView.contentOffset = .zero
            scrollView.frame = view.bounds
            scrollView.clipsToBounds = false
            scrollView.bounces = true
            scrollView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
            scrollView.isScrollEnabled = false
        }

        webViewManager.webView?.isUserInteractionEnabled = false

        // Setup top navigation controller
        topNavController.configure(
            topMenuView: topMenuView,
            webView: webViewManager.webView,
            containerBounds: view
        )
        topNavController.updateLayout()
    }

    private func setupCursor() {
        cursorController.setup(in: view)
        cursorController.isHidden = false
        cursorMode = true
    }

    private func setupGestures() {
        // Double tap on touch surface to toggle mode
        touchSurfaceDoubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTouchSurfaceDoubleTap))
        touchSurfaceDoubleTapRecognizer.numberOfTapsRequired = 2
        touchSurfaceDoubleTapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        view.addGestureRecognizer(touchSurfaceDoubleTapRecognizer)

        // Double tap Play/Pause for advanced menu
        playPauseDoubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handlePlayPauseDoubleTap))
        playPauseDoubleTapRecognizer.numberOfTapsRequired = 2
        playPauseDoubleTapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        view.addGestureRecognizer(playPauseDoubleTapRecognizer)
    }

    // MARK: - Navigation

    private func onWebViewDidAppear() {
        if let savedURL = settings.savedURLToReopen, !savedURL.isEmpty {
            webViewManager.loadURL(savedURL)
            settings.savedURLToReopen = nil
        } else if webViewManager.request == nil {
            loadHomePage()
        }

        if !settings.dontShowHintsOnLaunch && !displayedHintsOnLaunch {
            showUsageGuide()
        }
    }

    func loadHomePage() {
        webViewManager.loadURL(settings.homepage)
    }

    // MARK: - Mode Toggle

    func toggleMode() {
        cursorMode.toggle()

        if let scrollView = webViewManager.scrollView {
            scrollView.isScrollEnabled = !cursorMode
        }
        webViewManager.webView?.isUserInteractionEnabled = !cursorMode
        cursorController.isHidden = !cursorMode
    }

    // MARK: - Gesture Handlers

    @objc private func handleTouchSurfaceDoubleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            toggleMode()
        }
    }

    @objc private func handlePlayPauseDoubleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            showAdvancedMenu()
        }
    }

    // MARK: - Remote Input

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesEnded(presses, with: event)
            return
        }

        remoteHandler.handlePress(press, in: self)
    }

    // MARK: - Touch Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        cursorController.resetLastTouchLocation()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        cursorController.handleTouchMoved(touch, in: view)

        // Update cursor appearance
        guard webViewManager.request != nil, cursorMode else { return }

        let cursorPoint = cursorController.cursorPosition
        let webViewPoint = view.convert(cursorPoint, to: webViewManager.webView)

        // Don't check if in menu area
        if webViewPoint.y < 0 { return }

        // Scale point for JavaScript
        let displayWidth = webViewManager.getDisplayWidth()
        guard displayWidth > 0 else { return }

        let scale = (webViewManager.webView?.frame.width ?? 0) / CGFloat(displayWidth)
        let scaledPoint = CGPoint(x: webViewPoint.x / scale, y: webViewPoint.y / scale)

        let isClickable = webViewManager.isClickableElement(at: scaledPoint)
        cursorController.setPointerMode(isClickable)
    }
}

// MARK: - WebViewManagerDelegate

extension BrowserViewController: WebViewManagerDelegate {

    func webViewDidStartLoad() {
        if previousURL != requestURL {
            loadingSpinner.startAnimating()
        }
        previousURL = requestURL
    }

    func webViewDidFinishLoad(title: String, url: String) {
        loadingSpinner.stopAnimating()
        lblUrlBar.text = url

        // Update font size
        webViewManager.updateFontSize(settings.textFontSize)

        // Add to history
        historyManager.addEntry(url: url, title: title)
    }

    func webViewDidFailLoad(error: Error) {
        loadingSpinner.stopAnimating()

        let nsError = error as NSError
        // Ignore cancelled and frame load interrupted errors
        if nsError.code == -999 || nsError.code == -204 {
            return
        }

        alertPresenter.showLoadError(
            error: error,
            requestURL: requestURL,
            canReload: webViewManager.request != nil,
            onGoogleSearch: { [weak self] in
                guard let self = self else { return }
                var searchURL = self.requestURL
                if searchURL.hasSuffix("/") {
                    searchURL = String(searchURL.dropLast())
                }
                searchURL = searchURL
                    .replacingOccurrences(of: "http://", with: "")
                    .replacingOccurrences(of: "https://", with: "")
                    .replacingOccurrences(of: "www.", with: "")
                self.webViewManager.loadURL("https://www.google.com/search?q=\(searchURL)")
            },
            onReload: { [weak self] in
                self?.previousURL = ""
                self?.webViewManager.reload()
            },
            onNewURL: { [weak self] in
                self?.showQuickMenu()
            }
        )
    }

    func webViewShouldStartLoad(with request: URLRequest) -> Bool {
        requestURL = request.url?.absoluteString ?? ""
        return true
    }
}

// MARK: - Menu Presentation (will be moved to AlertPresenter)

extension BrowserViewController {

    func showQuickMenu() {
        alertPresenter.showQuickMenu(
            canGoForward: webViewManager.canGoForward,
            hasRequest: webViewManager.request != nil,
            onForward: { [weak self] in self?.webViewManager.goForward() },
            onInput: { [weak self] in self?.showInputURLorSearch() },
            onReload: { [weak self] in
                self?.previousURL = ""
                self?.webViewManager.reload()
            }
        )
    }

    func showAdvancedMenu() {
        alertPresenter.showAdvancedMenu(
            isTopMenuShowing: topNavController.isShowing,
            isMobileMode: settings.isMobileMode,
            scalesPageToFit: webViewManager.scalesPageToFit,
            onToggleTopNav: { [weak self] in self?.topNavController.toggle() },
            onGoHome: { [weak self] in self?.loadHomePage() },
            onSetHomePage: { [weak self] in
                guard let url = self?.webViewManager.currentURL, !url.isEmpty else { return }
                self?.settings.homepage = url
            },
            onShowFavorites: { [weak self] in self?.showFavorites() },
            onShowHistory: { [weak self] in self?.showHistory() },
            onToggleMobileMode: { [weak self] in self?.toggleMobileMode() },
            onToggleScaling: { [weak self] in self?.toggleScaling() },
            onIncreaseFontSize: { [weak self] in
                self?.settings.increaseFontSize()
                self?.webViewManager.updateFontSize(self?.settings.textFontSize ?? 100)
            },
            onDecreaseFontSize: { [weak self] in
                self?.settings.decreaseFontSize()
                self?.webViewManager.updateFontSize(self?.settings.textFontSize ?? 100)
            },
            onClearCache: { [weak self] in
                URLCache.shared.removeAllCachedResponses()
                self?.previousURL = ""
                self?.webViewManager.reload()
            },
            onClearCookies: { [weak self] in
                HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
                self?.previousURL = ""
                self?.webViewManager.reload()
            },
            onShowGuide: { [weak self] in self?.showUsageGuide() }
        )
    }

    func showInputURLorSearch() {
        alertPresenter.showURLInput(
            onGoToURL: { [weak self] urlString in
                self?.webViewManager.loadURL(urlString)
            },
            onSearch: { [weak self] query in
                let encoded = query
                    .replacingOccurrences(of: " ", with: "+")
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
                self?.webViewManager.loadURL("https://www.google.com/search?q=\(encoded)")
            }
        )
    }

    func showFavorites() {
        alertPresenter.showFavorites(
            favorites: favoritesManager.favorites,
            currentURL: webViewManager.currentURL ?? "",
            currentTitle: webViewManager.getDocumentTitle(),
            onSelect: { [weak self] favorite in
                self?.webViewManager.loadURL(favorite.url)
            },
            onAdd: { [weak self] url, title in
                self?.favoritesManager.add(url: url, title: title)
            },
            onDelete: { [weak self] index in
                self?.favoritesManager.remove(at: index)
            }
        )
    }

    func showHistory() {
        alertPresenter.showHistory(
            entries: historyManager.entries,
            onSelect: { [weak self] entry in
                self?.webViewManager.loadURL(entry.url)
            },
            onClear: { [weak self] in
                self?.historyManager.clear()
            }
        )
    }

    func showUsageGuide() {
        alertPresenter.showUsageGuide(
            dontShowOnLaunch: settings.dontShowHintsOnLaunch,
            onToggleDontShow: { [weak self] dontShow in
                self?.settings.dontShowHintsOnLaunch = dontShow
            }
        )
    }

    private func toggleMobileMode() {
        // Save current URL to reopen after mode switch
        if let url = webViewManager.currentURL, !url.isEmpty {
            settings.savedURLToReopen = url
        }

        settings.toggleMobileMode()

        // Clear cookies and cache, reinitialize
        HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        URLCache.shared.removeAllCachedResponses()

        // Remove and recreate webview
        webViewManager.webView?.removeFromSuperview()
        setupWebView()
        view.bringSubviewToFront(cursorController.cursorView)
        onWebViewDidAppear()
    }

    private func toggleScaling() {
        let newValue = !webViewManager.scalesPageToFit
        settings.scalesPagesToFit = newValue
        webViewManager.scalesPageToFit = newValue
        if newValue {
            webViewManager.webView?.contentMode = .scaleAspectFit
        }
        webViewManager.reload()
    }
}

// MARK: - Cursor Click Handling

extension BrowserViewController {

    func handleCursorClick() {
        let cursorPoint = cursorController.cursorPosition

        // Check if clicking in top menu area
        let menuPoint = view.convert(cursorPoint, to: topMenuView)
        if menuPoint.y >= 0 && topNavController.isShowing {
            handleTopMenuClick(at: menuPoint)
            return
        }

        // Handle click in webview
        let webViewPoint = view.convert(cursorPoint, to: webViewManager.webView)
        if webViewPoint.y < 0 { return }

        // Scale point for JavaScript
        let displayWidth = webViewManager.getDisplayWidth()
        guard displayWidth > 0 else { return }

        let scale = (webViewManager.webView?.frame.width ?? 0) / CGFloat(displayWidth)
        let scaledPoint = CGPoint(x: webViewPoint.x / scale, y: webViewPoint.y / scale)

        // Click the element
        webViewManager.clickElement(at: scaledPoint)

        // Check if it's an input field
        if let fieldType = webViewManager.getElementType(at: scaledPoint) {
            handleInputField(type: fieldType, at: scaledPoint)
        }
    }

    private func handleTopMenuClick(at point: CGPoint) {
        // Expand hit areas slightly
        let backFrame = btnImageBack.frame.insetBy(dx: 0, dy: -8)
        let menuFrame = btnImgMenu.frame.insetBy(dx: -100, dy: -100)

        if backFrame.contains(point) {
            webViewManager.goBack()
        } else if btnImageRefresh.frame.contains(point) {
            webViewManager.reload()
        } else if btnImageForward.frame.contains(point) {
            webViewManager.goForward()
        } else if btnImageHome.frame.contains(point) {
            loadHomePage()
        } else if lblUrlBar.frame.contains(point) {
            showInputURLorSearch()
        } else if btnImageFullScreen.frame.contains(point) {
            topNavController.toggle()
        } else if menuFrame.contains(point) {
            showAdvancedMenu()
        }
    }

    private func handleInputField(type: String, at point: CGPoint) {
        let inputTypes = ["date", "datetime", "datetime-local", "email", "month", "number",
                         "password", "search", "tel", "text", "time", "url", "week"]

        guard inputTypes.contains(type) else { return }

        let title = webViewManager.getElementAttribute("title", at: point) ?? type
        let placeholder = webViewManager.getElementAttribute("placeholder", at: point) ?? "Text Input"
        let currentValue = webViewManager.getElementAttribute("value", at: point) ?? ""
        let hasFormSubmit = webViewManager.hasFormSubmit(at: point)

        alertPresenter.showTextInput(
            fieldType: type,
            title: title,
            placeholder: placeholder,
            currentValue: currentValue,
            hasFormSubmit: hasFormSubmit,
            onDone: { [weak self] value in
                self?.webViewManager.setInputValue(value, at: point, submit: false)
            },
            onSubmit: { [weak self] value in
                self?.webViewManager.setInputValue(value, at: point, submit: true)
            }
        )
    }
}

// MARK: - Menu Button / Exit Handling

extension BrowserViewController {

    func handleMenuButtonPress() {
        // Try to go back in webview
        if webViewManager.canGoBack {
            webViewManager.goBack()
        } else {
            // Can't go back - show exit confirmation
            showExitConfirmation()
        }
    }

    func showExitConfirmation() {
        alertPresenter.showExitConfirmation {
            exit(EXIT_SUCCESS)
        }
    }
}
