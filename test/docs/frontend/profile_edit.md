# Profile Edit Specification – MediMind

## 1. Purpose of this document
This document specifies the profile editing flow, including user input validation, Firebase Auth updates, Firestore merge behavior, and user feedback rules.

---

## 2. Scope
Implementation file: `lib/presentation/screens/edit_profile_screen.dart`

Covered areas:
- Editable account fields and profile image selection.
- Password update with reauthentication requirement.
- Optional age storage and validation.
- Auth + Firestore synchronization after save.

---

## 3. Screen state model

### Controllers
- `_nameController`
- `_emailController`
- `_ageController`
- `_currentPasswordController`
- `_newPasswordController`

### Runtime flags/resources
- `_imageFile` for selected local profile image.
- `_isLoading` for blocking save state.
- `FirebaseAuth.instance.currentUser` as identity source.

### Initialization
- Name and email prefilled from FirebaseAuth user.
- Optional age loaded from `users/{uid}` in Firestore.

---

## 4. Validation rules

### Password update rule
- If a new password is provided, current password is required.
- Missing current password triggers snackbar and aborts save.

### Age validation rule
- Empty age is allowed.
- If provided, age must parse to integer in range `[0, 130]`.
- Invalid input triggers snackbar and aborts save.

---

## 5. Save flow (`_updateProfile`)

1. Validate password and age inputs.
2. Set loading state (`_isLoading = true`).
3. If password change requested:
   - Reauthenticate with `EmailAuthProvider.credential(...)`.
   - Call `updatePassword(newPassword)`.
4. If image selected:
   - Update auth `photoURL` using selected local path.
5. If display name changed:
   - Call `updateDisplayName(newName)`.
6. Merge profile metadata in Firestore (`users/{uid}`):
   - `fullName`
   - `updatedAt` server timestamp
   - `age` or field delete when empty
7. Reload Firebase user and return success feedback.
8. In `finally`, clear loading state when mounted.

---

## 6. Error handling contract

### FirebaseAuthException mapping
- `wrong-password` -> clear corrective message.
- `requires-recent-login` -> re-login guidance.
- `weak-password` -> password strength warning.

### UX guarantees
- Errors are surfaced via snackbar.
- Success path shows confirmation then returns to previous screen.

---

## 7. Lifecycle and resource rules
- All text controllers must be disposed in `dispose()`.
- Loading state updates must be guarded by `mounted`.
- `_pickImage()` must ignore null picker result.

---

## 8. What must NOT be changed
- Reauthentication requirement for password updates.
- Age validation boundaries (`0..130`) unless product/legal requirements change.
- Firestore merge strategy (`SetOptions(merge: true)`) for profile updates.
- Auth `reload()` step after save.

---

## 9. Future enhancements
- Replace local path `photoURL` approach with Firebase Storage URL upload flow.
- Add inline field error indicators to reduce snackbar-only feedback.
