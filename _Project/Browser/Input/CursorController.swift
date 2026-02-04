//
//  CursorController.swift
//  AeroTV
//
//  Virtual cursor movement and appearance
//

import UIKit

final class CursorController {

    // MARK: - Properties

    private(set) var cursorView: UIImageView!
    private var lastTouchLocation = CGPoint(x: -1, y: -1)

    // Screen bounds for cursor limits
    private let screenWidth: CGFloat = 1920
    private let screenHeight: CGFloat = 1080

    // MARK: - Computed Properties

    var cursorPosition: CGPoint {
        cursorView.frame.origin
    }

    var isHidden: Bool {
        get { cursorView.isHidden }
        set { cursorView.isHidden = newValue }
    }

    // MARK: - Setup

    func setup(in view: UIView) {
        cursorView = UIImageView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        cursorView.center = CGPoint(
            x: UIScreen.main.bounds.midX,
            y: UIScreen.main.bounds.midY
        )
        cursorView.image = .defaultCursor
        view.addSubview(cursorView)
    }

    // MARK: - Touch Handling

    func resetLastTouchLocation() {
        lastTouchLocation = CGPoint(x: -1, y: -1)
    }

    func handleTouchMoved(_ touch: UITouch, in view: UIView) {
        let location = touch.location(in: view)

        // First touch - initialize position without jumping
        if lastTouchLocation == CGPoint(x: -1, y: -1) {
            lastTouchLocation = location
            return
        }

        // Calculate delta
        let deltaX = location.x - lastTouchLocation.x
        let deltaY = location.y - lastTouchLocation.y

        // Apply delta to cursor
        var rect = cursorView.frame

        let newX = rect.origin.x + deltaX
        let newY = rect.origin.y + deltaY

        // Clamp to screen bounds
        if newX >= 0 && newX <= screenWidth {
            rect.origin.x = newX
        }
        if newY >= 0 && newY <= screenHeight {
            rect.origin.y = newY
        }

        cursorView.frame = rect
        lastTouchLocation = location
    }

    // MARK: - Cursor Appearance

    func setPointerMode(_ isPointer: Bool) {
        cursorView.image = isPointer ? .pointerCursor : .defaultCursor
    }

    func resetToDefault() {
        cursorView.image = .defaultCursor
    }
}
