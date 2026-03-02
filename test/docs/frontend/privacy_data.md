# Privacy & Data Rights Specification – MediMind

## 1. Purpose of this document
This document specifies the privacy and data-rights frontend flow, including export behavior, account deletion protections, and legal-information interactions.

---

## 2. Scope
Implementation file: `lib/presentation/screens/privacy_screen.dart`

Covered areas:
- GDPR action tiles and legal content dialogs.
- Right-of-Access export flow.
- Reauthenticated full-account deletion flow.
- Local/remote data cleanup order.

---

## 3. Screen structure and user actions

### Sections
- **Your Data Rights (GDPR)**
- **Legal**
- **Account Termination**

### Primary actions
- Right of Access (`_exportData`)
- Data Processing info popup
- Privacy Policy popup
- Cookie Preferences popup
- Delete Account (`_showDeleteDialog` -> `_reauthenticateAndDelete`)

---

## 4. Right-of-Access export flow

### Method
- `_exportData(BuildContext context)`

### Sequence
1. Ensure user is signed in.
2. Show modal loading indicator.
3. Load medications from Firestore, merging:
   - user-owned docs (`userId == uid`)
   - legacy docs with null user id
4. Generate PDF through `PdfService.generateHealthReport(meds)`.
5. On exception, show failure snackbar.
6. Always close loading dialog in `finally`.

### Constraint
- Export must remain tied to authenticated context and not run anonymously.

---

## 5. Delete-account protection flow

### Confirmation dialog
- `_showDeleteDialog` collects current password before destructive action.

### Reauthentication
- `_reauthenticateAndDelete` uses `EmailAuthProvider.credential(...)`.
- Deletion proceeds only if reauth succeeds.

### Deletion sequence (`_deleteEverything`)
1. Delete `medical_ids/{uid}`.
2. Query and delete user documents in `user_medications`.
3. Delete `dose_logs` through collection-group query by `userId`.
4. Clear local Hive boxes:
   - `drugs`
   - `medical_id_data`
   - `medication_stock`
5. Delete Firebase Auth account.
6. Reset navigation stack to login screen.

### Critical rule
- Auth account deletion must remain last to avoid orphaned cloud/local data.

---

## 6. Accessibility and reading support
- Info dialogs include integrated `SpeakerButton` for text-to-speech playback.
- Closing dialog triggers `TTSService.instance.stopIfSpeaking()`.

---

## 7. What must NOT be changed
- Reauthentication requirement before account deletion.
- Deletion order (data first, auth account last).
- Hive box cleanup targets used in privacy flow.
- Dialog `finally` cleanup for export loader.

---

## 8. Future enhancements
- Add visible deletion progress states for long-running cleanup.
- Add configurable privacy contact endpoint in policy text.
