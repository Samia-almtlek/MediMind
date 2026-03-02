# Home Actions Specification – MediMind

## 1. Purpose of this document
This document specifies the Home screen actions layer, including medication completion updates, management actions, and report export behavior.

---

## 2. Scope
Implementation file: `lib/presentation/screens/home_screens.dart`

Covered areas:
- Medication stream loading and real-time UI updates.
- Completion toggle logic and Firestore persistence.
- Manage Medications bottom-sheet actions.
- Health report export flow from Home.

---

## 3. Medication loading and synchronization

### Source of truth
- Firestore collection: `user_medications`
- Filter: `where('userId', isEqualTo: currentUser.uid)`
- Listener type: `snapshots().listen(...)`

### Behavior details
- If no authenticated user exists, UI list is reset to empty.
- Incoming snapshots map to `Medication.fromFirestore(doc)`.
- UI updates are performed through `setState` after snapshot events.

### Reliability constraints
- `_medicationsSubscription` must be canceled in `dispose()`.
- UI update guard (`if (!mounted) return`) must be preserved.

---

## 4. Completion toggle flow

### Method
- `_toggleMedicationCompletion(Medication med, bool isChecked)`

### Logic sequence
1. Normalize selected date to day precision (`DateTime(year, month, day)`).
2. Clone `completedDates` to avoid mutating shared references.
3. Add or remove target date based on checkbox state.
4. Update in-memory medication list for immediate UI feedback.
5. Persist full updated date list to Firestore as `Timestamp` array.

### Data contract
- Firestore field updated: `completedDates`
- Stored type: `List<Timestamp>`

### Constraint
- Medication without `id` must not trigger a Firestore write.

---

## 5. Manage Medications bottom sheet

### Entry point
- Method: `_showMoreActions()`

### Action set
- **Generate Health Report (PDF):** calls `_generateHealthReportFromHome()`.
- **Edit medication:** navigates to `ManualInputScreen(medicationToEdit: med)`.
- **Delete medication:** opens confirm dialog and then deletion logic.

### UX behavior
- Uses modal bottom sheet with rounded top corners.
- Shows fallback text when no active medications exist.
- Keeps action hierarchy explicit: export first, then per-medication actions.

---

## 6. PDF export from Home

### Method
- `_generateHealthReportFromHome()`

### Sequence
1. Validate authentication status.
2. Show blocking loader dialog.
3. Load report inputs:
   - User medications
   - FAQ questions
   - Doctor referral insights
4. Call `PdfService.generateHealthReport(...)`.
5. Show error snackbar on failure.
6. Close loader dialog in `finally`.

### Constraint
- Loader dialog must always be dismissed (`finally`) to avoid locked UI.

---

## 7. What must NOT be changed
- Firestore user filter in `_loadInitialData()`.
- Day-level date normalization before completion writes.
- Mandatory `finally` cleanup path for export dialog dismissal.
- Parameter handoff to `ManualInputScreen` for medication editing.

---

## 8. Future enhancements
- Add optimistic write rollback if Firestore update fails.
- Introduce grouped bulk actions for multiple medications.
- Add structured telemetry around completion toggles and export outcomes.
