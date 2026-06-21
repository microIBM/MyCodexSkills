# Example Prompts

Use these prompts inside a SwiftUI macOS app repository after installing the skill.

## Full redesign pass

```text
Use $swiftui-glass-ui-designer to upgrade this SwiftUI macOS app with a premium native glass-style interface. Inspect the project first, create a reusable design system, apply it consistently, preserve all business logic, do not change models/networking/persistence/auth/payments/subscriptions, build the app, and summarize changed files.
```

## Conservative polish pass

```text
Use $swiftui-glass-ui-designer for a conservative visual polish pass. Do not change layout structure unless necessary. Create reusable glass components, improve cards/buttons/navigation, preserve all business logic, keep the UI calm and readable, then build the app.
```

## Audit before editing

```text
Use $swiftui-glass-ui-designer to audit this SwiftUI macOS app before editing. Identify likely UI files, existing design-system files, duplicated styling, weak contrast, accessibility gaps, and any files that must remain off-limits because they contain business logic.
```

## Accessibility pass

```text
Use $swiftui-glass-ui-designer to audit the glass UI implementation for accessibility. Check Reduce Transparency, light mode, dark mode, contrast, hover states, selected states, keyboard focus, and duplicated styling. Fix UI issues only and preserve behavior.
```

## Design-system extraction

```text
Use $swiftui-glass-ui-designer to refactor existing scattered glass styling into reusable SwiftUI components and modifiers. Preserve the current look and behavior as much as possible, reduce duplication, and build the app afterward.
```

## Menu-bar app polish

```text
Use $swiftui-glass-ui-designer to polish this SwiftUI macOS menu-bar app interface. Focus on the popover, settings screen, onboarding, cards, buttons, hover states, and visual consistency. Preserve all feature behavior and do not edit models, services, stores, networking, persistence, authentication, payments, subscriptions, or analytics.
```

## Release smoke test

```text
Use $swiftui-glass-ui-designer for a release smoke test in this SwiftUI macOS app. Audit only, do not edit files, identify visual-system opportunities, name off-limits business logic files, and report the build command a real implementation should run.
```
