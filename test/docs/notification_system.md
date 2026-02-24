#  MediMind – Notification Subsystem Documentation

---

#  PRODUCTION STATUS (IMPORTANT)

The Cloud Notification Backend has already been:

* ✅ Initialized
* ✅ Configured
* ✅ Connected to production Firebase project
* ✅ Deployed successfully
* ✅ Linked to Cloud Scheduler
* ✅ Connected to SendGrid
* ✅ Secured with Firebase Secrets
* ✅ Indexed in Firestore
* ✅ Running on Blaze plan

⚠️ All setup steps have already been completed by me.

No additional setup is required from team members.

---

# 🛑 DO NOT RE-RUN SETUP

Team members must NOT execute:

```
firebase init functions
firebase deploy
firebase functions:secrets:set
firebase init
```

Reason:

* May overwrite production functions
* May remove or override secret keys
* May break Scheduler triggers
* May cause billing or permission conflicts
* May accidentally deploy unfinished code

The backend system is already live and operational.

---

#  Architecture Overview

The MediMind Notification Subsystem is a hybrid medical compliance engine designed to ensure:

* Timely medication reminders
* Automatic missed dose detection
* Caregiver escalation
* Stock monitoring
* Privacy protection
* Fail-safe backend fallback

System design:

Local-first → Backend fallback → Escalation

---

#  TYPE 1 — Medication Reminder Engine

When a medication dose is created:

* A `dose_logs` document is generated in Firestore
* Status is set to `"pending"`
* Three local notifications are scheduled:

  * T0
  * T0 + 5 minutes
  * T0 + 10 minutes

Local notifications handle fast reminders.

Backend ensures safety if local logic fails.

---

## Firestore Structure — dose_logs

Each dose contains:

* id
* userId
* medicatieId
* medicatieNaam
* geplandeTijd
* ingenomenTijd
* status (pending / taken / missed)
* reminderCount
* escalatieVerzonden
* escalatieTijd
* scheduledNotificationIds

---

## When User Presses “Taken”

* status → becomes `"taken"`
* ingenomenTijd stored
* Future reminders ignored
* Stock decremented

---

## If User Ignores All Reminders

After reminder 3:

* System waits 1 minute
* If still `"pending"`
* Status becomes `"missed"`
* Backend escalation logic handles caregiver notification

---

#  TYPE 2 — Caregiver Escalation Engine

Handled by deployed Firebase Cloud Function:

`checkMissedDoses`

Triggered automatically via Cloud Scheduler every 5 minutes.

Query logic:

* status == pending
* geplandeTijd <= now - 11 minutes
* escalatieVerzonden == false

If matched:

* status → missed
* Email sent via SendGrid
* Entry logged in escalation_logs
* escalatieVerzonden set to true

Prevents duplicate escalation.

---

#  TYPE 3 — Stock Monitoring Engine

Each medication contains:

* quantity
* intake frequency

Calculation:

remainingDays = quantity / dailyIntake

If remainingDays ≤ 3 → Low stock alert triggered.

Stock behavior:

| Action  | Result                   |
| ------- | ------------------------ |
| Taken   | Decrement stock          |
| Uncheck | Restore stock            |
| Refill  | Add to existing quantity |

No negative stock allowed.
No alert spam.

---

#  Lock Screen Privacy Layer

Hive box: `notification_settings`
Field: `hideSensitive`

If enabled:

Notification shows:

"Time to take your medication"

Instead of:

"Time to take Paracetamol"

Applies to:

* Medication reminders
* Low stock alerts

---

#  Difference Between Running & Deploying

## Running the App

```
flutter run
```

Executes:

* Local notifications
* Firestore writes
* UI
* Local stock logic

It does NOT affect Cloud Functions.

---

## Deploying Functions (Production Operation)

```
firebase deploy --only functions
```

Pushes new backend logic to production.

Affects:

* Missed detection
* Email escalation
* Scheduler logic
* Billing usage

⚠️ This should only be done by the backend owner.

---

#  What Team Members Should Do

Only:

* firebase login
* firebase use (ensure correct project)
* flutter run

No deploy required.
No secrets configuration required.
No scheduler configuration required.

---

#  Final Status

The MediMind Notification System is:

* Production deployed
* Backend secured
* Scheduler active
* Email escalation functional
* Firestore indexed
* Hybrid fail-safe architecture implemented

The system is fully operational.

