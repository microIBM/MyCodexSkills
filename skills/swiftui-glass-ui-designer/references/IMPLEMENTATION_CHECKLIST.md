# Implementation Checklist

Use this checklist during a SwiftUI macOS glass redesign.

## Before editing

- [ ] Identify app entry point.
- [ ] Identify main shell/navigation.
- [ ] Identify primary screens.
- [ ] Identify reusable components already present.
- [ ] Identify current color/theme files.
- [ ] Identify deployment target and SDK constraints.
- [ ] Identify build command.
- [ ] Identify likely SwiftUI view files with `rg` or `scripts/find_swiftui_views.py`.
- [ ] Search for likely non-UI files with terms such as `URLSession`, `SwiftData`, `CoreData`, `StoreKit`, `RevenueCat`, `Keychain`, `Auth`, `Subscription`, `Payment`, and `Analytics`.
- [ ] Identify files that contain business logic and should stay read-only.
- [ ] Make a short implementation plan that names expected UI files to edit.

## UI safety

- [ ] Edit only presentation-layer SwiftUI code.
- [ ] Preserve all existing actions, callbacks, bindings, tasks, queries, and side effects.
- [ ] Do not change models, stores, services, clients, repositories, persistence, networking, authentication, authorization, payments, subscriptions, analytics, or feature calculations.
- [ ] Do not change app routing, user flows, navigation destinations, entitlements, signing, bundle identifiers, dependencies, or deployment target.
- [ ] If a file mixes UI and behavior, make minimal visual edits and leave behavior branches intact.
- [ ] Stop and explain if the requested visual change requires behavior changes.

## Design system

- [ ] Create or extend theme tokens.
- [ ] Define corner radius scale.
- [ ] Define material strategy.
- [ ] Define stroke opacity strategy.
- [ ] Define shadow scale.
- [ ] Define spacing defaults.
- [ ] Define hover/press animations.
- [ ] Add Reduce Transparency fallback.
- [ ] Keep component APIs small and compatible with the existing project style.
- [ ] Avoid unused abstractions and avoid styling every container just because it exists.

## Components

- [ ] Glass background.
- [ ] Glass panel.
- [ ] Glass card.
- [ ] Glass button.
- [ ] Glass navigation item.
- [ ] Glass sheet/modal container if needed.

## Application

- [ ] Main window background updated.
- [ ] Main content container updated.
- [ ] Sidebar/navigation updated.
- [ ] Primary cards updated.
- [ ] Primary buttons updated.
- [ ] Settings screens updated.
- [ ] Onboarding screens updated if present.
- [ ] Popovers/sheets updated if present.

## Quality

- [ ] No major one-off duplicated styling remains.
- [ ] Light mode reviewed.
- [ ] Dark mode reviewed.
- [ ] Reduce Transparency reviewed.
- [ ] Text contrast reviewed.
- [ ] Hover/pressed/selected states reviewed.
- [ ] Existing app behavior preserved.
- [ ] Build passes.

## Diff review

- [ ] Run `git diff --stat` when Git is available.
- [ ] Inspect the actual diff, not only the file list.
- [ ] Confirm changed files are UI, design-system, preview, or visual asset files.
- [ ] Search for accidental changes involving `URLSession`, persistence, authentication, payments, subscriptions, analytics, reducers, stores, model calculations, routing, or feature flags.
- [ ] Revert your own unintended non-UI edits or stop and ask before proceeding.

## Final summary

- [ ] Changed files listed.
- [ ] Design system explained.
- [ ] Build command and result reported.
- [ ] Business-logic safety confirmed.
- [ ] Manual review areas noted.
