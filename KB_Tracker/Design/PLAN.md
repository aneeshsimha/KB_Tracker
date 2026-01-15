# Design Directory

This directory contains the app's design system - colors, typography, and shared visual constants.

---

## Files

### Colors.swift

**Purpose:** Central color definitions for the dark/tactical theme

**Implementation:**

```swift
import SwiftUI

extension Color {
    // Add hex initializer
    init(hex: String) {
        // Parse hex string to RGB values
    }
}

struct AppColors {
    static let background = Color(hex: "#050505")      // Near-black
    static let surface = Color(hex: "#111111")         // Cards, elevated surfaces
    static let border = Color(hex: "#222222")          // Subtle borders
    static let textPrimary = Color.white               // Main text
    static let textSecondary = Color(hex: "#666666")   // Secondary/muted text
    static let accent = Color.white                    // Buttons, highlights
    static let warning = Color(hex: "#FF3B30")         // Overtime indicator
}
```

**Notes:**
- The hex initializer is essential - SwiftUI doesn't have built-in hex support
- Consider adding `opacity` variants for common use cases
- All colors should be static to avoid re-computation

---

### Typography.swift

**Purpose:** Font definitions and text styles

**Implementation:**

```swift
import SwiftUI

struct AppTypography {
    // Timer display - large, monospace for alignment
    static let timer = Font.system(size: 72, weight: .bold, design: .monospaced)

    // Round counter
    static let roundCounter = Font.system(size: 24, weight: .semibold)

    // Section headers (WEIGHT, DURATION, etc.)
    static let sectionHeader = Font.system(size: 12, weight: .medium)

    // Body text
    static let body = Font.system(size: 16, weight: .regular)

    // Button labels
    static let button = Font.system(size: 18, weight: .semibold)

    // App title
    static let title = Font.system(size: 28, weight: .bold, design: .default)
}
```

**Notes:**
- Use `.monospacedDigit()` modifier on timer fonts to prevent layout shifts as numbers change
- Consider tracking (letter-spacing) adjustments for headers
- System fonts (SF Pro) are used - no custom fonts needed

---

## Dependencies

- None (this is a foundational module)

---

## Used By

- All Views and Components will import these definitions
- Should be imported via `import SwiftUI` (Colors/Typography are extensions)
