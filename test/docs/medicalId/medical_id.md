# Medical ID Implementation – MediMind

## 1. Purpose of this document
This document describes the implementation of the Medical ID feature. This module is critical for user safety, storing life-saving information such as blood types, allergies, and emergency caregiver contacts.

---

## 2. Feature Overview
The Medical ID serves as a digital emergency card within the app.
- **Core Info:** Stores blood type and a dynamic list of allergies.
- **Emergency Contact:** Manages caregiver details via Firestore sub-collections.
- **Accessibility:** Includes a Text-to-Speech (TTS) summary for emergency situations.
- **Hybrid Storage:** Uses local caching (Hive) for instant access and cloud storage (Firestore) for persistence.

---

## 3. Tools & Technologies
- **Hive:** Local NoSQL database for instant data loading (`medical_id_data` box).
- **Cloud Firestore:** Remote database for synchronization.
- **TTSService:** Custom service for converting medical data into audible summaries.
- **Equatable:** Used in the Domain layer to simplify object comparisons.

---

## 4. Data Architecture
The implementation follows Clean Architecture principles, separating the business definition from the data logic.

### Medical ID (Main Document)
- **Entity:** `MedicalIdEntity` (Domain layer, uses Equatable).
- **Model:** `MedicalIdModel` (Data layer, handles Firestore `Map` conversion).

### Caregiver (Sub-collection)
- **Entity:** `CaregiverEntity` (Domain layer).
- **Model:** `CaregiverModel` (Data layer, handles `Timestamp` and `userId` mapping).

---

## 5. Firestore Data Structure
The data is partitioned to allow for scalable caregiver management and security:

| Path | Data Type | Key Fields |
| :--- | :--- | :--- |
| `medical_ids/{uid}` | Main Doc | `bloodType`, `allergies`, `updatedAt` |
| `medical_ids/{uid}/caregivers/primary_contact` | **Sub-collection** | `name`, `email`, `relation`, `isActive` |

---

## 6. Implementation Logic

### Hybrid Loading (Cache-First)
1. **Immediate:** Data is read from the **Hive** box during `initState`.
2. **Sync:** A background fetch pulls the latest data from **Firestore**.
3. **Update:** If Firestore data differs, the UI and local Hive cache are updated.

### Save Flow
- Uses `SetOptions(merge: true)` to prevent overwriting existing data.
- Updates the main document and the caregiver sub-collection in parallel.
- Refreshes the local Hive cache upon success.

### TTS Summary
The `_buildMedicalSummary()` method compiles state variables into a natural language string:
> *"Blood type is A+. Allergies include: Penicillin. Emergency contact is John Doe..."*

---

## 7. UI Components
- **Edit Mode:** A toggle state (`isEditing`) that switches between read-only `Chips` and interactive `TextFields`.
- **Allergy Tags:** Uses a `Wrap` widget with `Chip` components for a modern, tag-based UI.
- **Loading Indicators:** A synchronized spinner in the `AppBar` tracks Firestore operations.

---

## 8. Technical Constraints & Security
> [!IMPORTANT]
> **Sub-collection Dependency:** Emergency contact info is stored in the `caregivers` sub-collection. When deleting or migrating user data, both the main document and the sub-collection must be handled.

- **TTS Cleanup:** `TTSService.instance.stopIfSpeaking()` is called in `dispose()` to prevent audio artifacts.
- **Field Keys:** The Model maps `userId` to the database key `userId` (Main) and uses `addedAt` for timestamps.

---

## 9. What must NOT be changed
- **Hive Box Name:** `medical_id_data`.
- **Caregiver Doc ID:** `primary_contact` (ensures a single primary contact).
- **Collection Names:** `medical_ids` and `caregivers`.

---

## 10. Future Enhancements
- Integration with the system-level "Emergency SOS" features.
- Support for multiple caregivers within the sub-collection.
- Photo upload for the Medical ID (using Firebase Storage).