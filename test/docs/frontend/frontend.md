# Frontend Implementation – MediMind

## 1. Purpose of this document
This document describes the frontend implementation delivered in MediMind, focusing on navigation structure, major screen UX, and user-facing actions tied to Firebase/Hive logic.

This file is the primary documentation for the full frontend implementation. The additional specification files represent deep-dive technical breakdowns of selected high-impact flows.

---

## 2. Scope
- Main app shell and tab navigation behavior.
- Home management UX for medication actions.
- Chatbot frontend design and conversation UX.
- Profile editing and account data update flow.
- Privacy & data rights screen interactions.
- Shared visual consistency through the app color system.

### Covered frontend screens
- `main_screen.dart`
- `splash_screen.dart`
- `home_screens.dart`
- `schedule_screen.dart`
- `chat_screen.dart`
- `profile_screen.dart`
- `edit_profile_screen.dart`
- `privacy_screen.dart`
- `support_screen.dart`
- `notification_settings_screen.dart`
- `medications_screen.dart`
- `medical_id_screen.dart`
- `add_choice_screen.dart`
- `scan_barcode_screen.dart`
- `manual_input_screen.dart`
- `treatment_duration_screen.dart`
- `success_screen.dart`

All frontend work is included in this scope. The specification files are only used to provide extra implementation detail for specific flows that needed clearer technical traceability.

---

## 3. Detailed specification files (deep dives)
- Home actions specification: `test/docs/frontend/home_actions.md`
- Profile edit specification: `test/docs/frontend/profile_edit.md`
- Privacy & data rights specification: `test/docs/frontend/privacy_data.md`

These files complement this overview and should be read as zoomed-in technical references, not as a limit on the overall frontend.

---

## 4. Main app shell & navigation

### MainScreen orchestration
Implemented in `presentation/screens/main_screen.dart`:
- Bottom navigation with four destinations: Home, Schedule, Chat, Profile.
- Contextual floating action button (visible on Home only) for adding medication.
- Controlled screen switching via `_selectedIndex`.
- Post-frame setup for initial local data loading and first-time tour check.

### Navigation consistency
- Maintains predictable tab behavior by keeping a single scaffold host.
- Uses a shared visual language with `AppColors.primaryBlue`, `AppColors.lightTeal`, and neutral contrast.

---

## 5. Home UX and interaction layer

### Medication data integration
Implemented in `presentation/screens/home_screens.dart`:
- Live Firestore subscription for user medications (`user_medications` filtered by `userId`).
- Defensive behavior when no authenticated user is available.
- Instruction parsing helper to extract explicit medication times from structured text.

### Daily actions UX
- Check/uncheck medication completion with local state update + Firestore sync (`completedDates`).
- Manage Medications bottom sheet for edit/delete actions.
- Direct PDF export action from Home (`Generate Health Report`) reusing the report service.

### Reliability choices
- Explicit `StreamSubscription` cancellation and `ScrollController` disposal in `dispose()`.
- Loading and failure feedback using blocking progress dialog + snackbars.

---

## 6. Profile editing frontend

### Edit profile screen
Implemented in `presentation/screens/edit_profile_screen.dart`:
- Editable profile inputs (username, email view, optional age, password update).
- Profile image selection from gallery via `image_picker`.
- Input validation for password-change flow and age boundaries.
- Firestore profile merge update (`users/{uid}`) + FirebaseAuth display name/photo synchronization.

### UX behavior
- Shows loading state while save operation runs.
- Maps FirebaseAuth errors to understandable feedback (wrong password, weak password, recent login required).
- Refreshes auth user state and returns to previous screen on success.

---

## 7. Privacy screen frontend
Implemented in `presentation/screens/privacy_screen.dart`:
- GDPR-oriented action tiles (Right of Access export, policy/processing details, account deletion).
- Dialog-driven information display with text-to-speech support.
- Export action integrated with `PdfService.generateHealthReport`.
- Controlled deletion flow with password reauthentication before destructive operations.

---

## 8. What must NOT be changed
- Main tab structure order in `MainScreen` (Home, Schedule, Chat, Profile) unless product requirements change.
- `user_medications` user filter behavior in Home, otherwise cross-user data can be displayed.
- Validation guard requiring current password before password updates in Edit Profile.
- Data-rights actions wording/intent in Privacy screen without legal review.

---

## 9. Future frontend improvements
- Introduce centralized snackbar/error utility for consistent messaging.
- Add form-level validation states (inline messages) in Edit Profile.
- Add loading skeletons for Home lists during initial Firestore sync.
