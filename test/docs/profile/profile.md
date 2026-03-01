# Profile & User Management Implementation – MediMind

## 1. Purpose of this document
This document details the implementation of the Profile system in MediMind. It covers user data synchronization with Firebase, the interactive onboarding tour, and the architectural representation of a MediMind user.

---

## 2. Feature Overview
The Profile module serves as the central hub for account management and app settings.
- **User Identity:** Displays and updates Firebase Auth data (DisplayName, Email, Photo).
- **Interactive Onboarding:** Features a guided "Feature Tour" using the `tutorial_coach_mark` package.
- **Settings Management:** Controls for notifications, privacy, medical data, and support access.
- **State Synchronization:** Includes logic to force-refresh Firebase user tokens and data after local updates.

---

## 3. Tools & Technologies
- **Tutorial Coach Mark:** For creating the high-contrast feature walkthrough.
- **Shared Preferences:** Used to persist the `profile_tour_seen` flag so the tutorial only plays once.
- **Firebase Auth:** The primary source for user authentication and basic profile metadata.
- **Cloud Firestore:** Stores extended user metadata via the `UserModel`.
- **Image Picker/File System:** Handles both network images and local file paths for profile photos.

---

## 4. Data Architecture
MediMind follows a strict separation between the Domain and Data layers for user management.

### UserEntity (Domain)
The fundamental blueprint of a MediMind user.
- **Fields:** Includes `id`, `email`, `name`, `profilePhotoUrl`, and timestamp data.
- **Preferences:** Stores the `notificationsEnabled` boolean state.

### UserModel (Data)
The implementation layer that handles external data formats.
- **Serialization:** Provides `fromFirestore` and `toFirestore` methods.
- **Mapping:** Corrects null values and handles the conversion between Dart `DateTime` and Firestore `Timestamp`.

---

## 5. Implementation Logic

### Interactive Feature Tour
The screen uses `GlobalKeys` to identify specific UI elements (Avatar, Medical ID, etc.) for the tutorial.
1. **Detection:** On first load, `SharedPreferences` checks if the tour has been seen.
2. **Execution:** If not seen, a `TutorialCoachMark` is triggered.
3. **Smooth Navigation:** If a target is off-screen, the `_scrollToKey` method uses the `ScrollController` to automatically bring the element into view before highlighting it.

### Profile Refresh Cycle
Since Firebase Auth data (like `photoURL`) does not always trigger a UI rebuild automatically, the `_refreshUser` method:
- Calls `user.reload()`.
- Triggers `setState()` to fetch the updated `currentUser` instance from the Auth singleton.

---

## 6. UI Structure & Components
The profile is organized into logical sections:
- **Header:** Profile picture with a camera overlay for quick edits.
- **Account Settings:** Link to `EditProfileScreen`.
- **Manage Health:** Direct navigation to Medication and Medical ID modules.
- **Preferences:** A quick-toggle `Switch` for notifications and link to Privacy settings.
- **Account:** Support links and the Logout action.

---

## 7. Technical Constraints & Security
> [!IMPORTANT]
> **Authentication State:** The profile screen relies on a valid `FirebaseAuth.instance.currentUser`. If the user logs out, the logic within `onTap` for the logout item handles the sign-out, relying on the `AuthGate` to reroute the user to the Login screen.

- **Photo Handling:** The UI supports both `NetworkImage` (for synced photos) and `FileImage` (for local uploads) via string prefix detection.
- **Tour Resilience:** The `addIfVisible` helper ensures the tutorial doesn't crash if a specific UI element is not rendered in the current build context.

---

## 8. What must NOT be changed
- **Preference Key:** `profile_tour_seen` (Changing this will reset the tour for all users).
- **GlobalKey Mapping:** Do not remove the `keys` attached to ListTiles as they are essential for the tutorial positioning.
- **Model Keys:** Firestore keys (`email`, `name`, `profilePhotoUrl`) must remain consistent with the database schema.

---

## 9. Future Enhancements
- Integration with Firebase Storage for permanent profile photo hosting.
- Advanced notification preference granularity (e.g., sound types, reminder intervals).
- Account deletion workflow following GDPR data erasure protocols.