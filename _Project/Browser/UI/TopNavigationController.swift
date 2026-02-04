//
//  TopNavigationController.swift
//  AeroTV
//
//  Top navigation bar visibility and layout management
//

import UIKit

final class TopNavigationController {

    // MARK: - Properties

    private weak var topMenuView: UIVisualEffectView?
    private weak var webView: UIView?
    private weak var containerBounds: UIView?

    private let settings = BrowserSettings.shared

    // MARK: - Computed Properties

    var isShowing: Bool {
        !(topMenuView?.isHidden ?? true)
    }

    var browserOffset: CGFloat {
        isShowing ? (topMenuView?.frame.height ?? 0) : 0
    }

    // MARK: - Setup

    func configure(topMenuView: UIVisualEffectView?, webView: UIView?, containerBounds: UIView?) {
        self.topMenuView = topMenuView
        self.webView = webView
        self.containerBounds = containerBounds

        // Apply initial state from settings
        topMenuView?.isHidden = !settings.showTopNavigationBar
    }

    // MARK: - Toggle

    func toggle() {
        if isShowing {
            hide()
        } else {
            show()
        }
    }

    func hide() {
        topMenuView?.isHidden = true
        settings.showTopNavigationBar = false
        updateLayout()
    }

    func show() {
        topMenuView?.isHidden = false
        settings.showTopNavigationBar = true
        updateLayout()
    }

    // MARK: - Layout

    func updateLayout() {
        guard let container = containerBounds else { return }

        if isShowing {
            webView?.frame = CGRect(
                x: container.bounds.origin.x,
                y: container.bounds.origin.y + browserOffset,
                width: container.bounds.width,
                height: container.bounds.height - browserOffset
            )
        } else {
            webView?.frame = container.bounds
        }
    }
}
