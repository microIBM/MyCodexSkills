# Accessibility Rules

Use these rules when applying glass-style UI to a SwiftUI macOS app.

## Reduce Transparency

Always check `@Environment(\.accessibilityReduceTransparency)` in reusable glass components or modifiers.

When Reduce Transparency is enabled:

- replace translucent material with solid system backgrounds
- keep strokes subtle but visible
- preserve corner radii and spacing
- preserve hierarchy without relying on blur

Do not simply remove the background and leave text floating.

## Contrast

Glass surfaces often reduce contrast. Counteract that with:

- quieter backgrounds behind text
- stronger foreground opacity
- more solid card materials
- subtle scrims where needed
- clear selected states

Never place small text directly over a noisy gradient or image without a readable container.

## Light and dark mode

Verify both modes. Do not tune only for dark mode.

Common mistakes:

- white strokes too strong in light mode
- black shadows too heavy in dark mode
- text appearing washed out over ultra-thin material
- selected states disappearing in light mode

## Keyboard and focus

Preserve keyboard navigation and focus behavior. If creating custom buttons or navigation items, make sure they remain accessible SwiftUI controls where possible.

Prefer real `Button`, `Toggle`, `Picker`, `NavigationLink`, and native controls over gesture-only custom views.

Do not replace controls with `onTapGesture` wrappers unless the existing app already does so and there is no practical native-control alternative.

When custom labels hide text behind icons, provide an accessibility label that matches the visible intent.

## Motion sensitivity

Avoid constant animation. Keep transitions short, subtle, and purposeful.

If the project already checks motion accessibility, respect that pattern.

Do not add looping background animation or motion that is required to understand state.

## Do not hide affordances

Glass UIs can become too subtle. Interactive controls must still look clickable.

Ensure:

- buttons have hover states
- selected navigation is clearly selected
- disabled states are visually distinct
- destructive actions remain recognizable
