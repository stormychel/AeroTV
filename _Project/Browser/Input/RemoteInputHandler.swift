//
//  RemoteInputHandler.swift
//  AeroTV
//
//  Siri Remote button handling
//

import UIKit

final class RemoteInputHandler {

    // MARK: - Handle Press

    func handlePress(_ press: UIPress, in controller: BrowserViewController) {
        switch press.type {
        case .menu:
            handleMenuPress(in: controller)

        case .select:
            handleSelectPress(in: controller)

        case .playPause:
            handlePlayPausePress(in: controller)

        case .upArrow, .downArrow, .leftArrow, .rightArrow:
            // Arrow keys not used in this implementation
            break

        @unknown default:
            break
        }
    }

    // MARK: - Menu Button

    private func handleMenuPress(in controller: BrowserViewController) {
        // If alert is showing, dismiss it
        if let presented = controller.presentedViewController {
            presented.dismiss(animated: true)
            return
        }

        // Try to go back, or show exit confirmation
        controller.handleMenuButtonPress()
    }

    // MARK: - Select (Touch Surface Press)

    private func handleSelectPress(in controller: BrowserViewController) {
        // If not in cursor mode, do nothing (scroll mode handles its own input)
        guard controller.isInCursorMode else { return }

        // Handle cursor click
        controller.handleCursorClick()
    }

    // MARK: - Play/Pause

    private func handlePlayPausePress(in controller: BrowserViewController) {
        // Dismiss any presented alert
        if let presented = controller.presentedViewController {
            presented.dismiss(animated: true)
            return
        }

        // Show quick menu
        controller.showQuickMenu()
    }
}
