# PDF Generation Implementation – MediMind

## 1. Purpose of this document
This document explains how MediMind's PDF export feature is implemented for patient data portability and monthly medication reporting.

---

## 2. Feature overview
The export feature generates a structured health report PDF that combines medication, adherence, and emergency context into one shareable output.

- Entry points:
  - Home screen action (`Generate Health Report`)
  - Privacy screen action (`Right of Access`)
- Rendering engine: `pdf` package (`pw.Document` + `pw.MultiPage`)
- Output channel: `printing` package preview/print flow via `Printing.layoutPdf`

---

## 3. Packages & dependencies used
- `pdf`: builds and styles report documents (`pw.Document`, `pw.MultiPage`, tables, cards, chart-like sections).
- `printing`: opens print/preview flow via `Printing.layoutPdf`.
- `firebase_auth`: provides current user identity for patient context.
- `cloud_firestore`: loads medication stock and dose-log data used in report sections.
- `hive_flutter`: reads local Medical ID cache (`medical_id_data`) for emergency information.
- `medimind/domain/models/medication.dart`: typed medication model used as the report input contract.

---

## 4. Core implementation

### Service location
- `service/pdf_service.dart`

### Main API
- `PdfService.generateHealthReport(List<Medication> medications, { ... })`

### Data sources merged in report
- **FirebaseAuth:** Current user identity.
- **Firestore:** Medication stock and dose logs (`user_medications` + `dose_logs`).
- **Hive:** Medical ID local cache (`medical_id_data`) for blood type/allergies/contact.

---

## 5. Report composition flow
1. Resolve report date context and monthly label.
2. Compute adherence statistics from dose logs (with fallback strategy).
3. Load medication stock rows from Firestore.
4. Read emergency/medical metadata from Hive.
5. Build a multi-page PDF with:
   - Header and page footer
   - Current medication table
   - Stock/refill table
   - Adherence summary card
   - Weekly taken chart
   - Monthly taken table
   - FAQ and referral insight sections
   - Emergency contact footer
6. Open preview/print using `Printing.layoutPdf`.

---

## 6. Adherence logic details
- Monthly range is built using inclusive/exclusive timestamp boundaries.
- Scheduled doses are primarily read from `dose_logs` query window.
- If no logs exist for a medication, fallback scheduling is computed from active treatment days and frequency parsing.
- Weekly aggregation maps each taken entry to week buckets (1..5).

This dual strategy reduces empty-report issues when historical logging is partially missing.

---

## 7. Integration points in UI

### Home screen
- `presentation/screens/home_screens.dart`
- Uses `_generateHealthReportFromHome()` with loading dialog and error snackbar.
- Enriches report with FAQ questions and doctor referral insights.

### Privacy screen
- `presentation/screens/privacy_screen.dart`
- Uses `_exportData()` to support GDPR right-of-access export.

---

## 8. What must NOT be changed
- Hive box key `medical_id_data` (used directly by report builder).
- Firestore collection names used by report loading (`user_medications`, `dose_logs`).
- Public service method signature unless all call sites are updated together.

---

## 9. Future improvements
- Add explicit file save/share destination (instead of preview-only flow).
- Add graph legends and trend indicators for adherence sections.
- Sending the PDF into  the user's mailbox.
- Extract report sections into smaller builder classes for easier testing.
