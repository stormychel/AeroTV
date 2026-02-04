//
//  AlertPresenter.swift
//  AeroTV
//
//  Centralized UIAlertController presentations
//

import UIKit

final class AlertPresenter {

    // MARK: - Properties

    private weak var presentingController: UIViewController?

    // MARK: - Initialization

    init(presentingController: UIViewController) {
        self.presentingController = presentingController
    }

    // MARK: - Quick Menu

    func showQuickMenu(
        canGoForward: Bool,
        hasRequest: Bool,
        onForward: @escaping () -> Void,
        onInput: @escaping () -> Void,
        onReload: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: "Quick Menu", message: "", preferredStyle: .alert)

        if canGoForward {
            alert.addAction(UIAlertAction(title: "Go Forward", style: .default) { _ in onForward() })
        }

        alert.addAction(UIAlertAction(title: "Input URL or Search with Google", style: .default) { _ in onInput() })

        if hasRequest {
            alert.addAction(UIAlertAction(title: "Reload Page", style: .default) { _ in onReload() })
        }

        alert.addAction(UIAlertAction(title: nil, style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    // MARK: - URL Input

    func showURLInput(
        onGoToURL: @escaping (String) -> Void,
        onSearch: @escaping (String) -> Void
    ) {
        let alert = UIAlertController(title: "Enter URL or Search Terms", message: "", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.keyboardType = .URL
            textField.placeholder = "Enter URL or Search Terms"
            textField.returnKeyType = .done
        }

        alert.addAction(UIAlertAction(title: "Search Google", style: .default) { _ in
            let text = alert.textFields?.first?.text ?? ""
            if !text.isEmpty {
                onSearch(text)
            }
        })

        alert.addAction(UIAlertAction(title: "Go To Website", style: .default) { _ in
            let text = alert.textFields?.first?.text ?? ""
            if !text.isEmpty {
                onGoToURL(text)
            }
        })

        alert.addAction(UIAlertAction(title: nil, style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    // MARK: - Advanced Menu

    func showAdvancedMenu(
        isTopMenuShowing: Bool,
        isMobileMode: Bool,
        scalesPageToFit: Bool,
        onToggleTopNav: @escaping () -> Void,
        onGoHome: @escaping () -> Void,
        onSetHomePage: @escaping () -> Void,
        onShowFavorites: @escaping () -> Void,
        onShowHistory: @escaping () -> Void,
        onToggleMobileMode: @escaping () -> Void,
        onToggleScaling: @escaping () -> Void,
        onIncreaseFontSize: @escaping () -> Void,
        onDecreaseFontSize: @escaping () -> Void,
        onClearCache: @escaping () -> Void,
        onClearCookies: @escaping () -> Void,
        onShowGuide: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: "Advanced Menu", message: "", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Favorites", style: .default) { _ in onShowFavorites() })
        alert.addAction(UIAlertAction(title: "History", style: .default) { _ in onShowHistory() })
        alert.addAction(UIAlertAction(title: "Go To Home Page", style: .default) { _ in onGoHome() })
        alert.addAction(UIAlertAction(title: "Set Current Page As Home Page", style: .default) { _ in onSetHomePage() })

        let modeTitle = isMobileMode ? "Switch To Desktop Mode" : "Switch To Mobile Mode"
        alert.addAction(UIAlertAction(title: modeTitle, style: .default) { _ in onToggleMobileMode() })

        let navTitle = isTopMenuShowing ? "Hide Top Navigation bar" : "Show Top Navigation bar"
        alert.addAction(UIAlertAction(title: navTitle, style: .default) { _ in onToggleTopNav() })

        let scaleTitle = scalesPageToFit ? "Stop Scaling Pages to Fit" : "Scale Pages to Fit"
        alert.addAction(UIAlertAction(title: scaleTitle, style: .default) { _ in onToggleScaling() })

        alert.addAction(UIAlertAction(title: "Increase Font Size", style: .default) { _ in onIncreaseFontSize() })
        alert.addAction(UIAlertAction(title: "Decrease Font Size", style: .default) { _ in onDecreaseFontSize() })

        alert.addAction(UIAlertAction(title: "Clear Cache", style: .destructive) { _ in onClearCache() })
        alert.addAction(UIAlertAction(title: "Clear Cookies", style: .destructive) { _ in onClearCookies() })
        alert.addAction(UIAlertAction(title: "Usage Guide", style: .default) { _ in onShowGuide() })

        alert.addAction(UIAlertAction(title: nil, style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    // MARK: - Favorites

    func showFavorites(
        favorites: [Favorite],
        currentURL: String,
        currentTitle: String,
        onSelect: @escaping (Favorite) -> Void,
        onAdd: @escaping (String, String) -> Void,
        onDelete: @escaping (Int) -> Void
    ) {
        let alert = UIAlertController(title: "Favorites", message: "", preferredStyle: .alert)

        // List favorites
        for (index, favorite) in favorites.enumerated() {
            let title = favorite.title.isEmpty ? favorite.url : favorite.title
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                onSelect(favorite)
            })
        }

        // Delete option if favorites exist
        if !favorites.isEmpty {
            alert.addAction(UIAlertAction(title: "Delete a Favorite", style: .destructive) { [weak self] _ in
                self?.showDeleteFavorite(favorites: favorites, onDelete: onDelete)
            })
        }

        // Add current page
        alert.addAction(UIAlertAction(title: "Add Current Page to Favorites", style: .default) { [weak self] _ in
            self?.showAddFavorite(url: currentURL, suggestedTitle: currentTitle, onAdd: onAdd)
        })

        alert.addAction(UIAlertAction(title: nil, style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    private func showDeleteFavorite(favorites: [Favorite], onDelete: @escaping (Int) -> Void) {
        let alert = UIAlertController(title: "Delete a Favorite", message: "Select a Favorite to Delete", preferredStyle: .alert)

        for (index, favorite) in favorites.enumerated() {
            let title = favorite.title.isEmpty ? favorite.url : favorite.title
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                onDelete(index)
            })
        }

        alert.addAction(UIAlertAction(title: nil, style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    private func showAddFavorite(url: String, suggestedTitle: String, onAdd: @escaping (String, String) -> Void) {
        let alert = UIAlertController(title: "Name New Favorite", message: url, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.keyboardType = .default
            textField.placeholder = "Name New Favorite"
            textField.text = suggestedTitle
            textField.returnKeyType = .done
        }

        alert.addAction(UIAlertAction(title: "Save", style: .destructive) { _ in
            let title = alert.textFields?.first?.text ?? ""
            onAdd(url, title.isEmpty ? url : title)
        })

        alert.addAction(UIAlertAction(title: nil, style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    // MARK: - History

    func showHistory(
        entries: [HistoryEntry],
        onSelect: @escaping (HistoryEntry) -> Void,
        onClear: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: "History", message: "", preferredStyle: .alert)

        if !entries.isEmpty {
            alert.addAction(UIAlertAction(title: "Clear History", style: .destructive) { _ in onClear() })
        }

        for entry in entries {
            var title = entry.title
            if title.trimmingCharacters(in: .whitespaces).isEmpty {
                title = entry.url
            } else {
                title = "\(entry.title) - \(entry.url)"
            }

            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                onSelect(entry)
            })
        }

        alert.addAction(UIAlertAction(title: nil, style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    // MARK: - Text Input (for web forms)

    func showTextInput(
        fieldType: String,
        title: String,
        placeholder: String,
        currentValue: String,
        hasFormSubmit: Bool,
        onDone: @escaping (String) -> Void,
        onSubmit: @escaping (String) -> Void
    ) {
        let alert = UIAlertController(title: "Input Text", message: title.capitalized, preferredStyle: .alert)

        alert.addTextField { textField in
            switch fieldType {
            case "url":
                textField.keyboardType = .URL
            case "email":
                textField.keyboardType = .emailAddress
            case "tel", "number", "date", "datetime", "datetime-local":
                textField.keyboardType = .numbersAndPunctuation
            default:
                textField.keyboardType = .default
            }

            textField.placeholder = placeholder.capitalized
            textField.isSecureTextEntry = (fieldType == "password")
            textField.text = currentValue
            textField.returnKeyType = .done
        }

        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            let text = alert.textFields?.first?.text ?? ""
            onDone(text)
        })

        if hasFormSubmit {
            alert.addAction(UIAlertAction(title: "Submit", style: .destructive) { _ in
                let text = alert.textFields?.first?.text ?? ""
                onSubmit(text)
            })
        }

        alert.addAction(UIAlertAction(title: nil, style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    // MARK: - Usage Guide

    func showUsageGuide(
        dontShowOnLaunch: Bool,
        onToggleDontShow: @escaping (Bool) -> Void
    ) {
        let message = """
        Double press the touch area to switch between cursor & scroll mode.
        Press the touch area while in cursor mode to click.
        Single tap to Menu button to Go Back, or Exit on root page.
        Single tap the Play/Pause button to: Go Forward, Enter URL or Reload Page.
        Double tap the Play/Pause to show the Advanced Menu with more options.
        """

        let alert = UIAlertController(title: "Usage Guide", message: message, preferredStyle: .alert)

        let toggleTitle = dontShowOnLaunch ? "Always Show On Launch" : "Don't Show This Again"
        alert.addAction(UIAlertAction(title: toggleTitle, style: .destructive) { _ in
            onToggleDontShow(!dontShowOnLaunch)
        })

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    // MARK: - Load Error

    func showLoadError(
        error: Error,
        requestURL: String,
        canReload: Bool,
        onGoogleSearch: @escaping () -> Void,
        onReload: @escaping () -> Void,
        onNewURL: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: "Could Not Load Webpage",
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        if !requestURL.isEmpty {
            alert.addAction(UIAlertAction(title: "Google This Page", style: .default) { _ in
                onGoogleSearch()
            })
        }

        if canReload {
            alert.addAction(UIAlertAction(title: "Reload Page", style: .default) { _ in onReload() })
        } else {
            alert.addAction(UIAlertAction(title: "Enter a URL or Search", style: .default) { _ in onNewURL() })
        }

        alert.addAction(UIAlertAction(title: nil, style: .cancel))

        presentingController?.present(alert, animated: true)
    }

    // MARK: - Exit Confirmation

    func showExitConfirmation(onExit: @escaping () -> Void) {
        let alert = UIAlertController(title: "Exit App?", message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
            onExit()
        })

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))

        presentingController?.present(alert, animated: true)
    }
}
