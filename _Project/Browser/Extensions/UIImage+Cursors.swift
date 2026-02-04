//
//  UIImage+Cursors.swift
//  AeroTV
//

import UIKit

extension UIImage {
    static let defaultCursor: UIImage = {
        UIImage(named: "Cursor") ?? UIImage()
    }()

    static let pointerCursor: UIImage = {
        UIImage(named: "Pointer") ?? UIImage()
    }()
}
