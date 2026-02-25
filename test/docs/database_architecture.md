
# Database Architecture & Data Layer Implementation

## MediMind – Data Layer Documentation

---

##  Scope of This Work

This contribution focuses exclusively on:

* Designing the Firestore database structure
* Implementing the full Data Layer architecture
* Preparing all collections required for the MVP
* Creating a clean separation between UI and database
* Ensuring scalability for future backend logic



---

#  Architecture Overview

The database layer follows a clean architecture structure:

```
UI
 ↓
UseCases (future backend logic)
 ↓
Repository (Domain)
 ↓
RepositoryImpl (Data)
 ↓
FirestoreService
 ↓
Cloud Firestore
```

The UI does NOT communicate directly with Firestore.

---

#  Project Structure Implemented

##  Domain Layer

###  lib/domain/entities/

Entities represent pure business objects with no Firebase dependency.

Created entities:

* UserEntity
* ProductEntity
* UserMedicationEntity
* MedicatieSchemaEntity
* DoseLogEntity
* CaregiverEntity
* ChatSessionEntity
* ChatMessageEntity
* ScanLogEntity
* SearchHistoryEntity

These classes define the logical structure of the system.

---

###  lib/domain/repositories/

Abstract contracts for data access:

* UserRepository
* ProductRepository
* MedicationRepository
* ChatRepository
* HistoryRepository

These define WHAT the system can do (not HOW).

---

##  Data Layer

###  lib/data/models/

Models are responsible for:

* Converting Firestore JSON → Entity
* Converting Entity → Firestore Map

Each entity has a corresponding model:

* UserModel
* ProductModel
* UserMedicationModel
* MedicatieSchemaModel
* DoseLogModel
* CaregiverModel
* ChatSessionModel
* ChatMessageModel
* ScanLogModel
* SearchHistoryModel

---

###  lib/data/datasources/

#### firestore_service.dart

Centralized Firestore access layer.

Responsibilities:

* Typed collection references
* Generic CRUD helpers
* No business logic

Collections prepared:

* users
* product
* user_medications
* medicatie_schema
* dose_logs
* scan_logs
* search_history
* caregivers
* chat_sessions
* chat_messages

---

### 📁 lib/data/repositories_impl/

Repository implementations connecting Domain → Firestore:

* UserRepositoryImpl
* ProductRepositoryImpl
* MedicationRepositoryImpl
* ChatRepositoryImpl
* HistoryRepositoryImpl

Responsibilities:

* Convert Entity ↔ Model
* Call FirestoreService
* Return clean domain objects

---

#  Firestore Database Structure

The following collections are fully prepared:

### 👤 users

User profile data (already existing in project).

### 💊 product

Master medication catalog.

### 👤💊 user_medications

User-specific medications linked to product.

### 📅 medicatie_schema

Frequency & scheduling configuration per medication.

### 🕒 dose_logs

Tracks medication intake confirmations.

### 📷 scan_logs

Tracks barcode/OCR scans.

### 🔍 search_history

Tracks medication searches.

### 👨‍👩‍👧 caregivers

Stores caregiver relationships.

### 💬 chat_sessions

AI chatbot conversation sessions.

### 💬 chat_messages

Individual chatbot messages.

---



#  Full Data Flow Example

When a user adds medication:

1. UI triggers a UseCase (to be implemented)
2. UseCase calls Repository (domain contract)
3. RepositoryImpl converts Entity → Model
4. FirestoreService writes document
5. Firestore stores the document

The UI never directly accesses Firestore.

---

#  Current Status

✔ Database structure fully prepared
✔ All required collections exist
✔ Clean architecture separation applied
✔ Ready for backend logic implementation
✔ Ready for UI integration

---

#  Summary

This work delivers:

A complete, scalable, production-ready Firestore data layer.

It prepares MediMind for:

* Business logic implementation
* Cloud Functions integration
* Notification system
* AI chatbot backend
* Adherence analytics



