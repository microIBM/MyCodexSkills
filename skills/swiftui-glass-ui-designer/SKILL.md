---
name: swiftui-glass-ui-designer
description: Upgrade an existing SwiftUI macOS app to a polished native glass-style interface without changing product behavior. Use for SwiftUI macOS Liquid Glass-style redesigns, translucent panels, glass cards, glass buttons, floating control-center layouts, visual polish, accessibility-safe materials, and reusable UI design-system work. Do not use for backend, business logic, models, API, database, networking, persistence, authentication, payments, subscriptions, analytics, or non-SwiftUI projects.
---

# SwiftUI Glass UI Designer

Improve the visual interface of an existing SwiftUI macOS app. Create a polished, native, glass-style design system and apply it consistently without changing the product's behavior.

This skill is for presentation-layer SwiftUI work: UI architecture, visual polish, reusable view components, accessibility, and macOS-native presentation.

It is not for business logic, backend work, models, networking, persistence, authentication, payments, subscriptions, analytics, database logic, state-management behavior, or feature behavior changes.

## Core outcome

Transform the existing app into a refined macOS-native glass interface that feels calm, spacious, premium, readable, and intentional.

The result should feel like a modern floating macOS control center: soft translucent surfaces, subtle depth, generous spacing, capsule controls, smooth states, and strong hierarchy.

Do not make the app merely transparent. Build a reusable design system and apply it consistently.

Use this opinionated recipe:

1. Start with the app's existing information architecture.
2. Add one calm ambient window background, not a different backdrop per screen.
3. Use glass for structure: app shell, navigation selection, panels, cards, controls, and overlays.
4. Use at most two or three material strengths in the first pass.
5. Pair every translucent surface with readable foregrounds, subtle strokes, and Reduce Transparency fallbacks.
6. Prefer fewer stronger decisions over many decorative effects.

Do not add `.blur`, `.ultraThinMaterial`, gradients, shadows, or rounded rectangles everywhere. If a surface does not group content, indicate selection, or communicate hierarchy, leave it simpler.

## Safety contract

Treat this as a UI-only skill. Never change business logic.

Allowed changes:

- SwiftUI `View`, `ViewModifier`, `ButtonStyle`, `ToggleStyle`, `LabelStyle`, and presentation-only helper code.
- New or existing design-system files for colors, materials, spacing, radii, shadows, animation tokens, and reusable glass components.
- Asset or preview-only adjustments when they are strictly visual and do not affect runtime behavior.

Avoid changes to:

- models, stores, reducers, controllers, services, clients, repositories, migrations, schedulers, jobs, and dependency containers
- networking, persistence, authentication, authorization, payments, subscriptions, analytics, telemetry, permissions, and file I/O
- routing, navigation destinations, feature flags, user flows, validation rules, calculations, sorting, filtering, and data transformations
- deployment target, bundle identifiers, entitlements, capabilities, signing, package dependencies, or project structure unless the user explicitly asks for that non-UI work outside this skill

If a Swift file mixes views and logic, edit only the presentation code and preserve every existing branch, binding, action, callback, task, query, and side effect. If a visual change appears to require logic changes, stop and explain the tradeoff instead of making the logic change silently.

Before finishing, inspect the diff when a VCS is available. If non-UI files changed unexpectedly, revert your own unintended edits or stop and ask how to proceed.

## Bundled resources

Load only the resources needed for the task:

- `references/IMPLEMENTATION_CHECKLIST.md`: use before editing and before the final response.
- `references/SWIFTUI_COMPONENT_PATTERNS.md`: use when creating or refactoring glass components.
- `references/ACCESSIBILITY_RULES.md`: use when touching materials, contrast, controls, focus, or motion.
- `references/DESIGN_PRINCIPLES.md`: use when choosing or correcting the visual direction.
- `references/REVIEW_RUBRIC.md`: use for a larger redesign or final quality pass.
- `references/EXAMPLE_PROMPTS.md`: use only when the user asks how to invoke this skill.
- `scripts/find_swiftui_views.py`: optionally run from the target app root to inventory likely SwiftUI view files. It is read-only.

## First step: inspect before editing

Before writing code, inspect the repository and identify:

1. App entry point and window shell.
2. Main navigation structure.
3. Dashboard or primary content screens.
4. Cards, panels, sheets, popovers, toolbars, and settings views.
5. Existing reusable style components.
6. Current deployment target and Swift/Xcode compatibility.
7. Existing accessibility handling, especially color scheme and Reduce Transparency.

Useful discovery commands:

```bash
rg --files -g '*.swift'
rg '@main|WindowGroup|Settings|NavigationSplitView|NavigationStack|struct .+: View|var body: some View' -g '*.swift'
rg 'URLSession|SwiftData|CoreData|@Query|StoreKit|RevenueCat|Keychain|Auth|Subscription|Payment|Analytics' -g '*.swift'
python3 .agents/skills/swiftui-glass-ui-designer/scripts/find_swiftui_views.py
```

Use the third command to identify files that are likely off-limits for a visual pass. Use the helper script only if the skill is installed in the target repo. If it is unavailable, use `rg` directly.

Then make a short implementation plan that names the UI files you expect to touch and any files that are off-limits. Keep the first pass focused on the shell, navigation, primary screens, and reusable components. Proceed with implementation unless the user asked only for analysis.

## Design-system-first implementation

Create a small reusable glass design system before modifying many screens.

Prefer files like:

- `LiquidGlassTheme.swift` or `GlassTheme.swift`
- `GlassBackground.swift`
- `GlassPanel.swift`
- `GlassCard.swift`
- `GlassButton.swift`
- `GlassNavigationItem.swift`
- `GlassSheetContainer.swift`
- `LiquidGlassModifiers.swift` or `GlassModifiers.swift`

Prefer reusable modifiers like:

- `liquidGlassPanel()`
- `liquidGlassCard()`
- `liquidGlassButton()`
- `liquidGlassNavigationItem()`
- `liquidGlassSheet()`
- `liquidGlassHoverEffect()`

Use the project's existing naming conventions. If the app already has a design-system folder, place new files there.

Avoid one-off styling scattered across many screens. If you repeat a material, radius, stroke, shadow, animation, or spacing value more than twice, move it into the design system.

Do not introduce a large framework or dependency for visual styling. Prefer small SwiftUI components and modifiers that fit the existing project.

For a first pass, keep the design system compact: tokens plus the components the edited screens actually use. Do not create unused abstractions just because they sound plausible.

## Visual direction

Use a premium macOS glass aesthetic:

- translucent material surfaces
- floating panels
- rounded corners, usually 20-32 pt
- capsule buttons and selected states
- low-opacity strokes
- subtle highlight overlays
- soft shadows with restraint
- generous spacing
- calm hierarchy
- system typography
- light and dark mode support
- readable foregrounds
- smooth hover and press states

Avoid:

- making everything transparent
- adding blur to every container
- excessive blur
- low-contrast text
- neon gradients
- heavy black shadows
- thick borders
- web-app styling
- cluttered layouts
- aggressive animations
- randomly changing the product's structure

Glass should support the interface. It should not become the interface.

## Native macOS strategy

Use SwiftUI-native APIs wherever possible.

When the deployment target and SDK support newer Apple glass APIs, use them behind availability checks. Do not make the app require a newer OS unless the project already does.

For older macOS versions, use safe fallbacks such as:

- `.ultraThinMaterial`
- `.thinMaterial`
- `.regularMaterial`
- `RoundedRectangle`
- low-opacity strokes
- subtle overlays
- soft shadows
- solid system backgrounds when needed

Always keep compatibility with the project's current deployment target unless the user explicitly asks to raise it.

## Accessibility requirements

Respect accessibility from the beginning.

Always check and support:

- Reduce Transparency
- light mode
- dark mode
- text contrast
- keyboard focus
- readable hover and selected states
- Dynamic Type where relevant

When Reduce Transparency is enabled, replace glass surfaces with solid readable system backgrounds.

Do not sacrifice readability for a glass effect.

Prefer native controls (`Button`, `Toggle`, `Picker`, `NavigationLink`, `Menu`) over gesture-only custom controls so keyboard, focus, and assistive behavior stay intact.

## Motion rules

Use subtle animation only:

- hover brightness
- small press scale
- opacity transitions
- smooth selected states
- gentle panel transitions

Avoid springy, bouncy, flashy, or distracting motion unless the existing app already uses that style and the user requests it.

Motion should make the UI feel alive, not playful or noisy.

## Implementation order

1. Inspect the current UI and design structure.
2. Identify UI-only files to edit and behavior files to avoid.
3. Create or extend the reusable glass design system.
4. Apply the system to the app shell and window background.
5. Apply the system to navigation and selected states.
6. Apply the system to primary cards and panels.
7. Apply the system to buttons and controls.
8. Apply the system to sheets, popovers, onboarding, and settings.
9. Refactor duplicated visual styles.
10. Verify light mode, dark mode, and Reduce Transparency.
11. Build the project and fix compiler errors without broad rewrites.
12. Review the diff for accidental logic changes.
13. Summarize changed files and what the user should review visually.

## Suggested component behavior

### Glass background

Use a subtle ambient background behind glass surfaces. It may be a quiet gradient, blurred color field, or existing brand background. It should not compete with content.

### Glass panels

Panels should feel elevated and calm. Use material backgrounds, rounded continuous corners, low-opacity strokes, and soft shadows. Increase solidity if text readability suffers.

### Glass cards

Cards should structure content without looking like heavy boxes. Use consistent padding, radius, and hierarchy. Cards should be quieter than panels.

### Glass buttons

Primary buttons should feel like polished capsules. Secondary buttons should be quiet but still clearly interactive. Hover and pressed states should be visible but subtle.

### Navigation

Selected navigation items should use clear glass capsule states. Avoid harsh sidebar selection rectangles.

### Settings and onboarding

Settings and onboarding should use the same visual system as the main app. Do not let these screens look like a separate template.

## Verification

Run the most appropriate available build command. Prefer the project's documented command. If there is no documentation, infer from the repo:

- `swift build` for Swift Package apps and libraries when applicable.
- `xcodebuild -list` first for Xcode projects or workspaces, then build the relevant scheme.
- Existing test, lint, or formatting commands when they are clearly part of the project and not expensive.

After building, review changed files. In Git repositories, use `git diff --stat` and inspect the actual diff. Confirm that changes are limited to UI/presentation concerns. Watch for accidental edits involving `URLSession`, persistence, authentication, payments, subscriptions, analytics, reducers, stores, model calculations, or navigation behavior.

If the build cannot be run because the environment lacks Xcode, a scheme, signing, or dependencies, report the exact blocker and still perform a source-level safety review.

## Quality bar

The task is complete only when:

- the app builds successfully
- all new glass styling is reusable
- major screens share one coherent visual language
- text remains readable
- light mode works
- dark mode works
- Reduce Transparency works
- duplicated styling is minimized
- business logic is untouched
- the app still feels like the same product, only more polished

## Final response format

At the end, provide:

1. A short summary of the visual system created.
2. A list of changed files.
3. Build/test commands run and their result.
4. Confirmation that business logic was not changed, or a clear warning if the user requested a separate non-UI change.
5. Any visual areas the user should manually review.
6. Any intentional limitations or compatibility notes.

Do not oversell the result. Be honest if visual review is still needed.
