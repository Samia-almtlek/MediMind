# 💊 MediMind – Notification Subsystem Documentation

## 📌 Overview

The MediMind Notification Subsystem is a hybrid medical compliance engine designed to ensure:

* Timely medication reminders
* Automatic missed dose detection
* Caregiver escalation
* Stock monitoring
* Privacy protection
* Fail-safe backend fallback

The system uses:

* `flutter_local_notifications` (local reminders)
* Firebase Firestore (dose state tracking)
* Firebase Cloud Scheduler (server fallback)
* Firebase Cloud Functions
* SendGrid (email escalation)
* Hive (local storage)
* Hybrid architecture (local-first with backend safety)

---

# 🧠 Architecture Overview

## 🔁 Hybrid Reminder System

The system is designed as:

> Local-first → Backend fallback → Escalation

### Why Hybrid?

* Local notifications are fast and reliable.
* Backend ensures missed detection if:

  * App crashes
  * User force closes app
  * Device restarts
  * Local logic fails

This guarantees medical safety.

---

# 🔔 TYPE 1 — Medication Reminder Engine

## 📍 What Happens When a Dose Is Scheduled?

When a medication dose is created:

1. A `dose_log` document is generated in Firestore.
2. Status is set to `"pending"`.
3. Three local notifications are scheduled:

   * T0 → exact scheduled time
   * T0 + 5 minutes
   * T0 + 10 minutes

---

## 📂 Firestore Data Model (dose_logs)

Each dose contains:

```
id
userId
medicatieId
medicatieNaam
geplandeTijd
ingenomenTijd
status (pending / taken / missed)
reminderCount
escalatieVerzonden
escalatieTijd
scheduledNotificationIds
```

---

## 🟢 When User Presses “Taken”

* `status` → becomes `"taken"`
* `ingenomenTijd` is stored
* Future reminders are ignored
* Stock is decremented (Type 3 logic)

---

## 🔴 If User Ignores All 3 Reminders

After the third reminder:

* System waits 1 minute
* If still `pending`
* Status → `"missed"`

Then backend escalation handles caregiver notification.

---

# 🚨 TYPE 2 — Caregiver Escalation Engine

## 🎯 Purpose

Notify caregiver when a medication dose was missed.

---

## 🧩 Backend Logic

Handled by Firebase Cloud Function:

```
checkMissedDoses
```

Runs via Cloud Scheduler.

---

## 🔎 What It Checks

Firestore query:

* `status == pending`
* `geplandeTijd <= now - 11 minutes`
* `escalatieVerzonden == false`

If matched:

1. Update status → `"missed"`
2. Send email via SendGrid
3. Log event in `escalation_logs`
4. Set `escalatieVerzonden = true`

---

## 📧 Email Content

Includes:

* Medication name
* Caregiver name
* Clear missed warning

---

## 📂 Escalation Log Structure

Collection: `escalation_logs`

```
doseId
medicatieId
userId
caregiverId
caregiverEmail
medicationName
escalatedAt
```

Prevents duplicate alerts.

---

# 📦 TYPE 3 — Stock Monitoring Engine

## 🎯 Purpose

Ensure user never runs out of medication.

---

## 🧠 Logic

Each medication has:

* Quantity
* Intake frequency

System calculates:

```
remainingDays = quantity / dailyIntake
```

If remainingDays ≤ 3:

→ Trigger low stock alert

---

## 🔁 Stock Updates

| Action  | Behavior                 |
| ------- | ------------------------ |
| Taken   | Decrement stock          |
| Uncheck | Restore stock            |
| Refill  | Add to existing quantity |

No negative stock allowed.

No alert spam.

---

# 🔐 Lock Screen Privacy

## 🎯 Purpose

Protect sensitive medical data on lock screen.

---

## 🧩 Implementation

Hive box:

```
notification_settings
```

Toggle:

```
hideSensitive
```

If true:

Notification text becomes:

```
"Time to take your medication"
```

Instead of:

```
"Time to take Paracetamol"
```

Works for:

* Medication reminders
* Low stock alerts

---

# ☁️ Cloud Function Setup Guide

## 📌 Prerequisites

* Firebase project
* Blaze plan (required for Scheduler + SendGrid)
* Node 18+

---

## 1️⃣ Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

---

## 2️⃣ Initialize Functions

Inside project:

```bash
firebase init functions
```

Choose:

* JavaScript
* ESLint (optional)
* Install dependencies

---

## 3️⃣ Install SendGrid

Inside `functions` folder:

```bash
npm install @sendgrid/mail
```

---

## 4️⃣ Add Secret Key

```bash
firebase functions:secrets:set SENDGRID_KEY
```

Paste your SendGrid API key.

---

## 5️⃣ Deploy

```bash
firebase deploy --only functions
```

---

## 6️⃣ Setup Cloud Scheduler

In Firebase Console:

→ Functions
→ checkMissedDoses
→ Create Scheduler

Set:

* Every 5 minutes
* HTTP trigger
* Auth: require authentication

---

# 🔐 Firestore Index Setup

Because we use `collectionGroup("dose_logs")`
You must create a composite index.

When error appears:

Click provided Firebase link
Create index with:

* status
* userId (if used)
* **name**

Wait until status = ENABLED.

---

# 🧪 Testing Strategy (Manual)

## Reminder Test

1. Schedule medication 1 minute ahead
2. Wait
3. Confirm 3 reminders fire

---

## Missed Dose Test

1. Ignore all 3 reminders
2. Wait 11+ minutes
3. Confirm:

   * status becomes missed
   * caregiver email sent
   * escalation_logs entry created

---

## Stock Test

1. Set quantity = 3 days
2. Mark taken
3. Confirm alert appears

---

# 🏁 Conclusion

MediMind now contains:

* A hybrid medication reminder engine
* Automatic missed detection
* Caregiver escalation with backend safety
* Real-time stock monitoring
* Privacy protection layer
* Fail-safe architecture

