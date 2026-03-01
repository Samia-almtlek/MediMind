# Barcode Scanning Implementation – MediMind

## 1. Purpose of this document
This document explains how the barcode scanning feature is implemented and integrated with Firebase in the MediMind project. It ensures that the scanning logic, data models, and database logging remain consistent across the development team.

---

## 2. Feature Overview
The barcode scanner allows users to identify medication by scanning its retail barcode.
- **Scanning:** Real-time detection using the device camera.
- **Validation:** Matches scanned barcodes against the `product` collection in Firestore.
- **Logging:** Automatically records every scan attempt and successful search.
- **Accessibility:** Provides audio feedback via the `SpeakerButton`.

---

## 3. Tools & Dependencies
- **mobile_scanner:** For camera handling and QR/Barcode processing.
- **Cloud Firestore:** For medication lookups and activity logging.
- **Clean Architecture:** Uses Entity and Model patterns for data consistency.

---

## 4. Data Architecture
The feature uses a dual-layer data structure to handle scan logs:

### ScanLogEntity
- Located in: `domain/entities/scan_log_entity.dart`
- Responsibility: Defines the basic data structure (ID, UserID, Barcode, Timestamp).

### ScanLogModel
- Located in: `data/models/scan_log_model.dart`
- Responsibility: Handles Firestore serialization (`fromFirestore` and `toFirestore`).
- **Mapping Note:** The model maps the internal `userId` to the database key `gebruikerId`.

---

## 5. Firestore Data Structure
The scanner interacts with the following collections:

| Collection | Key Field | Purpose |
| :--- | :--- | :--- |
| **product** | `barcode` | Stores medication names and dosages. |
| **scan_logs** | `UserID` | Records every time the camera detects a code. |
| **search_history** | `UserID` | Records only when a product is successfully found. |

---

## 6. Implementation Logic
The scan process in `ScanBarcodeScreen` follows this flow:
1. **Detection:** `MobileScanner` captures a barcode string.
2. **State Management:** `isScanning` is set to `false` to prevent multiple simultaneous popups.
3. **Firestore Query:** `_firestore.collection('product').where('barcode', isEqualTo: barcode)` is called.
4. **Logging:** `_logScan()` and `_logSearchHistory()` execute to track user activity.
5. **UI Feedback:** A `ModalBottomSheet` displays the product info or a "Not Found" error.

---

## 7. UI Components
- **MobileScanner:** The camera preview widget.
- **SpeakerButton:** Integrated into the result sheet for text-to-speech accessibility.
- **DraggableScrollableSheet:** Used to display results without leaving the scanner screen.

---

## 8. Technical Constraints & Security
> [!IMPORTANT]
> **Authentication:** The `currentUserId` is currently hardcoded for development. This **MUST** be updated to use `FirebaseAuth.instance.currentUser!.uid` once the Auth module is merged.

- **Torch Control:** Managed via `MobileScannerController.toggleTorch()`.
- **Memory Management:** The controller must be disposed of in the `dispose()` method to avoid camera memory leaks.

---

## 9. What must NOT be changed
- **Collection Names:** Do not change `product`, `scan_logs`, or `search_history`.
- **Field Consistency:** The database uses `barcode` (String), not (Int).
- **Navigation Logic:** The "ADD MEDICINE" button must pass `title` and `subtitle` to the `TreatmentDurationScreen`.

---

## 10. Future Enhancements
- Fix the naming discrepancy between `UserID` (UI code) and `gebruikerId` (Model code).
- Implement offline caching for scanned products.