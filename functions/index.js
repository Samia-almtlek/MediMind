const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();

const SENDGRID_KEY = defineSecret("SENDGRID_KEY");

exports.checkMissedDoses = onRequest(
    {secrets: [SENDGRID_KEY]},
    async (req, res) => {
      try {
        sgMail.setApiKey(SENDGRID_KEY.value());

        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();

        // ⏳ Grace period (11 minutes)
        const graceMilliseconds = 11 * 60 * 1000;

        const graceLimit = admin.firestore.Timestamp.fromMillis(
            now.toMillis() - graceMilliseconds,
        );

        // 🔎 1️⃣ Get pending doses that passed grace period
        const snapshot = await db
            .collectionGroup("dose_logs")
            .where("status", "==", "pending")
            .where("geplandeTijd", "<=", graceLimit)
            .where("escalatieVerzonden", "==", false)
            .get();

        if (snapshot.empty) {
          return res.status(200).send("No missed doses.");
        }

        // 🔁 2️⃣ Process each missed dose
        for (const doc of snapshot.docs) {
          const dose = doc.data();

          const userId = dose.userId;
          const medicationName = dose.medicatieNaam || "Medication";

          // 🔎 3️⃣ Get active caregivers for this user
          const caregiversSnap = await db
              .collection("caregivers")
              .where("userId", "==", userId)
              .where("isActive", "==", true)
              .get();

          // 📧 4️⃣ Send email to each caregiver
          for (const caregiverDoc of caregiversSnap.docs) {
            const caregiver = caregiverDoc.data();

            await sgMail.send({
              to: caregiver.email,
              from: "samia.almoutlak@gmail.com",
              subject: "⚠ Medication Missed Alert",
              text: `Dear ${caregiver.name},

The medication "${medicationName}" was not taken after 3 reminders.

Please check on the user.

MediMind Team`,
            });

            // 📝 5️⃣ Log escalation
            await db.collection("escalation_logs").add({
              doseId: doc.id,
              medicatieId: dose.medicatieId,
              userId: userId,
              caregiverId: "primary_contact", 
              medicalId: userId,
              caregiverEmail: caregiver.email,
              medicationName: medicationName,
              escalatedAt: admin.firestore.FieldValue.serverTimestamp(),
              path: `medical_ids/${userId}/caregivers/primary_contact`,
            });
          }

          // 🔄 6️⃣ Update dose (single atomic update)
          await doc.ref.update({
            status: "missed",
            escalatieVerzonden: true,
            escalatieTijd: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        return res.status(200).send("Missed doses processed successfully.");
      } catch (error) {
        console.error("Error processing missed doses:", error);
        return res.status(500).send("Internal server error.");
      }
    },
);
