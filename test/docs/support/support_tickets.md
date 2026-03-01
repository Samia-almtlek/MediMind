# Support & Help Implementation – MediMind

## 1. Purpose of this document
This document outlines the implementation of the Support and FAQ module in MediMind. It details how users access help resources and how support tickets are handled within the system.

---

## 2. Feature Overview
The Support module provides a two-tier help system:
- **Self-Service:** A dynamic Frequently Asked Questions (FAQ) list with audio assistance.
- **Direct Support:** A ticketing system that allows users to submit specific queries directly to the MediMind team via Firestore.
- **Accessibility:** Full Text-to-Speech (TTS) integration for both screen orientation and FAQ answers.

---

## 3. Tools & Technologies
- **Cloud Firestore:** Stores and manages user-submitted support tickets.
- **Firebase Auth:** Identifies the user and associates their email with the ticket.
- **TTSService:** Provides voice-over capabilities for FAQ content.
- **AnimatedContainer:** Used for smooth transitions when expanding FAQ items.

---

## 4. Data Architecture
The module follows the established Clean Architecture pattern.

### SupportTicketEntity (Domain)
- Defines the core properties of a ticket (ID, UserID, Email, Question, Timestamp).
- Uses the `TicketStatus` enum (`open`, `inProgress`, `resolved`) to track the lifecycle of a request.

### SupportTicketModel (Data)
- Handles serialization to and from Firestore.
- Converts Dart `DateTime` objects to Firestore `Timestamp` objects.
- Maps the `TicketStatus` enum to a string for database compatibility via `.name`.

---

## 5. Firestore Data Structure
Tickets are stored in a centralized collection to allow administrative oversight.

**Collection Name:** `support_tickets`

| Field | Type | Description |
| :--- | :--- | :--- |
| `userId` | String | The UID of the sender. |
| `userEmail` | String | Used for follow-up communication. |
| `question` | String | The actual message/problem description. |
| `createdAt` | Timestamp | Server-side record of when the ticket was sent. |
| `status` | String | Current state (defaults to `open`). |

---

## 6. Implementation Logic

### FAQ Interaction
- FAQs are stored in a local list for instant loading.
- Tapping an FAQ expands the card via `AnimatedContainer`.
- **Audio Feedback:** Expanding an FAQ automatically triggers the `TTSService` to read the answer aloud, improving accessibility for visually impaired users.

### Ticket Submission Flow
1. **Validation:** The contact form ensures the message is not empty.
2. **Auth Check:** The system verifies the user is logged in to retrieve their UID and Email.
3. **Firestore Injection:** A `SupportTicketModel` is created and added to the `support_tickets` collection using `.add()`.
4. **User Feedback:** A `SnackBar` confirms successful submission and the modal is dismissed.

---

## 7. UI Components
- **Expandable FAQ Cards:** Built with `ListTile` and `AnimatedContainer` for a reactive feel.
- **Support Modal:** A `ModalBottomSheet` that handles text input without taking the user away from the Support context.
- **Accessibility Icon:** A volume button in the `AppBar` provides a general overview of the screen's purpose via TTS.

---

## 8. Technical Constraints & Security
> [!IMPORTANT]
> **Authentication Required:** Users cannot submit tickets if `FirebaseAuth.instance.currentUser` is null. An error SnackBar is shown as a fallback.

- **TTS Management:** To avoid overlapping audio, `TTSService.instance.stopIfSpeaking()` is called before any new speech starts and within the `dispose()` method.
- **Status Handling:** Statuses are strictly managed via the `TicketStatus` enum to prevent invalid state strings in the database.

---

## 9. What must NOT be changed
- **Collection Name:** `support_tickets`.
- **Enum Values:** The `TicketStatus` values must remain consistent as they are stored as strings.
- **Model Keys:** `userId`, `userEmail`, and `createdAt` must match the model's `toJson` logic exactly.

---

## 10. Future Enhancements
- **Admin Dashboard:** A separate interface to view and "resolve" tickets.
- **Real-time Chat:** Upgrading the ticketing system to a live chat via Firestore streams.
- **Search Bar:** Ability to search through a larger library of FAQ items.