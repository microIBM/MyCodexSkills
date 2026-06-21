# Design Principles

This reference defines the visual taste and boundaries for the SwiftUI Glass UI Designer skill.

## Principle 1: Glass is structure, not decoration

A glass interface should organize the app into clear layers: background, shell, navigation, panels, cards, controls, and overlays.

Do not add blur randomly to existing rectangles. Create a hierarchy where the glass effect helps users understand what is foreground, what is grouped, and what is interactive.

Default to one ambient background, a small set of material strengths, shared radii, and clear selected states. If a surface does not group content or signal interaction, it may not need glass at all.

## Principle 2: Readability beats transparency

The interface must remain readable in light mode, dark mode, and high-contrast situations. Increase material solidity, foreground opacity, or background quietness whenever text feels weak.

The goal is not maximum translucency. The goal is polished depth.

## Principle 3: Use fewer stronger decisions

A premium interface usually needs fewer effects, not more.

Prefer:

- one shared corner-radius scale
- one shared material strategy
- one shared shadow scale
- one shared button behavior
- one shared selected-state behavior

Avoid mixing many radii, many blur styles, many border strengths, and many button styles.

## Principle 4: Keep the app recognizable

Improve the existing product. Do not redesign it into a different app unless the user asks for that.

Preserve:

- information architecture
- feature layout intent
- content hierarchy
- user flows
- navigation behavior

## Principle 5: Keep changes presentation-only

Visual polish should not alter product behavior.

Preserve existing:

- actions and callbacks
- bindings and state ownership
- async tasks and side effects
- validation, sorting, filtering, and calculations
- persistence, networking, authentication, payments, subscriptions, analytics, and permissions

When behavior and UI are intertwined, make the smallest visual change that keeps the existing logic intact.

## Principle 6: Native first

Use SwiftUI and AppKit-native behavior before custom visual tricks.

The result should feel like a macOS app, not a website or Electron interface.

## Principle 7: Calm motion

Motion should communicate interaction and continuity. It should not distract.

Good motion:

- small scale on press
- gentle hover brightening
- smooth selected-state transitions
- soft panel appearing/disappearing

Bad motion:

- large bouncing
- excessive blur animation
- constant background movement
- dramatic transitions on everyday controls

## Principle 8: Accessibility is part of the aesthetic

Reduce Transparency support is not optional. A glass interface that fails accessibility is unfinished.

When accessibility settings reduce effects, the app should still look polished using solid backgrounds, consistent spacing, readable strokes, and clear hierarchy.
