# Interactive Tour Implementation – MediMind

## 1. Purpose of this document
This document describes the guided onboarding tours implemented to help users understand the core screens quickly without external training.

---

## 2. Feature overview
The tour system provides first-time contextual walkthroughs using highlighted UI targets and explanatory cards.

- Package: `tutorial_coach_mark`
- Persistence: `SharedPreferences`
- Behavior: each tour runs once per device/profile unless its flag is reset

---

## 3. Packages & dependencies used
- `tutorial_coach_mark`: builds spotlight targets (`TargetFocus`) and renders the guided overlay UI.
- `shared_preferences`: stores one-time tour flags (`main_tour_seen`, `home_tour_seen`, `schedule_tour_seen`, `chat_tour_seen`, `profile_tour_seen`).
- `flutter/material.dart`: provides core UI primitives, `GlobalKey`, and screen lifecycle hooks used by the tour flow.

---

## 4. Implemented tour surfaces

### Main navigation tour
- File: `presentation/screens/main_screen.dart`
- Persistence key: `main_tour_seen`
- Covers: Home tab, Schedule tab, Chat tab, Profile tab, Add Medication.

### Home screen tour
- File: `presentation/screens/home_screens.dart`
- Persistence key: `home_tour_seen`
- Covers: manage menu, horizontal calendar, dose checkmark action.

### Schedule screen tour
- File: `presentation/screens/schedule_screen.dart`
- Persistence key: `schedule_tour_seen`
- Covers: voice summary button, first treatment card details.

### Chat screen tour
- File: `presentation/screens/chat_screen.dart`
- Persistence key: `chat_tour_seen`
- Covers: assistant status badge, conversation area, input area.

### Profile screen tour
- File: `presentation/screens/profile_screen.dart`
- Persistence key: `profile_tour_seen`
- Covers: avatar, personal data, medication, medical ID, notifications, privacy, support, logout.
- Special behavior: split in top and bottom targets with automatic scrolling before the second part.

---

## 5. UX implementation approach
- Every tour uses GlobalKey anchors mapped to real widgets.
- Tour card styling is unified (title + message card with the app color palette).
- Skip button is explicitly styled and placed for visibility.
- Overlay opacity and focus padding are tuned for accessibility and readability.

---

## 6. Reliability safeguards
- Visibility checks before adding focus targets prevent null-context crashes.
- `mounted` checks are used before showing overlays or writing preferences.
- Profile flow uses `Scrollable.ensureVisible` to avoid highlighting off-screen targets.

---

## 7. What must NOT be changed
- SharedPreferences keys:
  - `main_tour_seen`
  - `home_tour_seen`
  - `schedule_tour_seen`
  - `chat_tour_seen`
  - `profile_tour_seen`
- GlobalKey-to-widget mapping for each target.
- Post-frame invocation pattern for showing tours after layout is ready.

---


