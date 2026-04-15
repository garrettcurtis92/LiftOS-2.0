import SwiftUI

enum LiftTheme {
    // MARK: - Semantic Colors

    /// Primary accent — system blue by default
    static let accent = Color.accentColor

    /// Success — set completion, workout finished
    static let success = Color.green

    /// Warning — deload, timer urgency
    static let warning = Color.orange

    /// Warmup set indicator
    static let warmup = Color.orange

    /// Deload week indicator
    static let deload = Color.orange

    /// PR / top set highlight
    static let highlight = Color.yellow

    // MARK: - Backgrounds

    /// Standard card / input field background
    static let cardBackground = Color(.secondarySystemBackground)

    /// Elevated surface (modals, overlays)
    static let elevatedBackground = Color(.tertiarySystemBackground)

    // MARK: - Corner Radii

    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let inputCornerRadius: CGFloat = 6

    // MARK: - Spacing

    static let cardSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let compactSpacing: CGFloat = 8
    static let listItemSpacing: CGFloat = 4
}
