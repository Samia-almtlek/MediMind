# Caregiver Data Implementation – MediMind

## 1. Purpose of this document
This document defines the structure and implementation of the Caregiver module. This data is primarily used within the Medical ID feature to identify and contact emergency representatives for the user.

---

## 2. Feature Overview
The Caregiver module manages the relationship between the user and their emergency contact.
- **Identity:** Stores the caregiver's name and contact email.
- **Relationship:** Defines the user's connection to the caregiver (e.g., Spouse, Parent, Doctor).
- **Status:** Tracks whether the caregiver is currently active as an emergency contact.
- **Persistence:** Synchronizes data between the application and the `caregivers` Firestore sub-collection.

---

## 3. Data Architecture
The module follows the clean architecture pattern, separating the business definition from the data logic.

### CaregiverEntity (Domain)
- **File:** `domain/entities/caregiver_entity.dart`
- **Responsibility:** The core blueprint used by the UI and business logic.
- **Fields:** - `id`: Unique identifier for the caregiver document.
  - `userId`: The ID of the user this caregiver is assigned to.
  - `isActive`: Boolean flag to enable/disable emergency notifications.
  - `addedAt`: Optional DateTime tracking when the contact was created.

### CaregiverModel (Data)
- **File:** `data/models/caregiver_model.dart`
- **Responsibility:** Extends the Entity to handle Firestore serialization.
- **Methods:**
  - `fromFirestore`: Converts a Firestore `DocumentSnapshot` into a model.
  - `fromMap`: A helper for raw Map conversion (useful for nested data).
  - `toFirestore`: Prepares data for database storage, converting `DateTime` to a Firestore `Timestamp` or using `FieldValue.serverTimestamp()`.

---

## 4. Firestore Data Mapping
Caregivers are stored as a **sub-collection** under a specific user's Medical ID to maintain data privacy and logical grouping.

**Storage Path:** `medical_ids/{userId}/caregivers/{caregiverId}`

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `name` | String | Full name of the contact. |
| `email` | String | Validated email address for emergency alerts. |
| `relation` | String | The relationship type (e.g., "Brother"). |
| `isActive` | Boolean | Determines if this contact is visible in Emergency Mode. |
| `addedAt` | Timestamp | Server-side record of when the entry was created. |

---

## 5. Key Implementation Details
- **Timestamp Handling:** The model safely handles the conversion between Dart’s `DateTime` and Firestore’s `Timestamp`, including null safety for new entries.
- **ID Management:** The `id` is captured directly from the Firestore `DocumentSnapshot` to ensure local and remote objects remain synced.
- **Default Values:** The `fromMap` factory provides fallback empty strings to prevent the app from crashing due to null or missing database fields.

---

## 6. What must NOT be changed
- **Field Keys:** The keys used in `toFirestore` (e.g., `userId`, `isActive`) must match the Firestore security rules exactly.
- **Inheritance:** `CaregiverModel` must always extend `CaregiverEntity` to ensure the Data layer remains compatible with the Domain layer.
- **Sub-collection Logic:** Caregivers should never be stored in a top-level collection; they must remain children of a `medical_id` document.

---

## 7. Future Enhancements
- Implementation of a `primaryCaregiver` flag if multiple caregivers are added.
- Integration with phone number validation for SMS emergency alerts.
- Profile picture support via Firebase Storage.