# AeroTV

A modern web browser for Apple TV (tvOS).

![AeroTV Browser](screen01.jpg)

> **Note**: This app uses private APIs and cannot be submitted to the App Store. It's designed for personal use via sideloading through Xcode.

## Features

- Full web browsing on Apple TV
- Virtual cursor for precise navigation
- Scroll mode for content-heavy pages
- Favorites and browsing history
- Desktop/Mobile user agent switching
- Adjustable font size and page scaling
- Cookie and cache management

## Requirements

- Apple TV 4th generation or later
- Mac with Xcode 15+
- Apple Developer account (free tier works)
- USB-C cable or wireless pairing (Apple TV 4K)

## Installation

1. Clone this repository
2. Open `_Project/Browser.xcodeproj` in Xcode
3. Update the Bundle Identifier to your own (e.g., `com.yourname.AeroTV`)
4. Select your Team in Signing & Capabilities
5. Connect your Apple TV (USB-C or wireless)
6. Build and run

### Wireless Setup (Apple TV 4K)

1. On Apple TV: Settings → Remotes and Devices → Remote App and Devices
2. In Xcode: Window → Devices and Simulators
3. Click "+" and select your Apple TV
4. Enter the pairing code shown on TV

## Usage

| Action | Control |
|--------|---------|
| Move cursor | Swipe on touch surface |
| Click | Press touch surface (cursor mode) |
| Switch cursor/scroll mode | Double-press touch surface |
| Quick Menu (URL, search, reload) | Single tap Play/Pause |
| Advanced Menu | Double tap Play/Pause |
| Go back | Press Menu button |

## Credits

- Original: [Steven Troughton-Smith](https://github.com/steventroughtonsmith)
- Improvements: [Jip van Akker](https://github.com/jvanakker)
- Modernization: This fork

## License

This software is provided as-is with no warranty. Use at your own risk.
