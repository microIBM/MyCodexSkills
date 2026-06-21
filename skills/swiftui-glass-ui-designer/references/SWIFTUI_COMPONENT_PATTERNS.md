# SwiftUI Component Patterns

These examples are patterns, not mandatory code. Adapt names and placement to the existing project.

Keep these components presentation-only. They should accept content, style state, or simple visual variants, but they should not own app data, start network work, persist settings, perform calculations, or decide feature behavior.

Use availability checks for newer SDK-only visual APIs and preserve the project's current deployment target.

## Glass theme tokens

```swift
import SwiftUI

enum GlassTheme {
    enum Radius {
        static let card: CGFloat = 24
        static let panel: CGFloat = 30
        static let button: CGFloat = 999
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }

    enum Animation {
        static let subtle = SwiftUI.Animation.easeOut(duration: 0.18)
    }
}
```

## Accessibility-safe glass panel

```swift
import SwiftUI

struct GlassPanel<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(GlassTheme.Spacing.large)
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: GlassTheme.Radius.panel, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.10), radius: 24, x: 0, y: 12)
    }

    @ViewBuilder
    private var panelBackground: some View {
        let shape = RoundedRectangle(cornerRadius: GlassTheme.Radius.panel, style: .continuous)

        if reduceTransparency {
            shape
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(shape.stroke(Color.primary.opacity(0.08), lineWidth: 1))
        } else {
            shape
                .fill(.ultraThinMaterial)
                .overlay(shape.stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.22), lineWidth: 1))
        }
    }
}
```

## Glass-style button

```swift
import SwiftUI

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default).weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule(style: .continuous)
                    .fill(reduceTransparency ? Color(nsColor: .controlBackgroundColor) : .thinMaterial)
                    .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.16), lineWidth: 1))
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.86 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
```

## Modifier wrapper

```swift
import SwiftUI

struct LiquidGlassCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: GlassTheme.Radius.card, style: .continuous)
                    .fill(reduceTransparency ? Color(nsColor: .controlBackgroundColor) : .regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: GlassTheme.Radius.card, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func liquidGlassCard() -> some View {
        modifier(LiquidGlassCardModifier())
    }
}
```

## Selected navigation capsule

```swift
import SwiftUI

struct GlassNavigationItemStyle: ButtonStyle {
    let isSelected: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default).weight(isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(reduceTransparency ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.18) : .thinMaterial)
                        .overlay(Capsule(style: .continuous).stroke(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.10), lineWidth: 1))
                }
            }
            .contentShape(Capsule(style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}
```
