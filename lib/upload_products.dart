// import 'package:cloud_firestore/cloud_firestore.dart';

// Future<void> uploadProducts() async {
//   final products = [
//     {
//       "name": "GALPHARM PARACETAMOL 500MG CAPLETS",
//       "dosage": "500mg",
//       "barcode": "5017353500809",
//       "description":
//           "GALPHARM Paracetamol 500mg Caplets provide effective relief from mild to moderate pain and fever. This 500mg formulation is commonly used for headaches, muscle aches, colds, and general discomfort."
//     },
//     {
//       "name": "Aspirin Dispersible Tabs 300mg 32s",
//       "dosage": "300mg",
//       "barcode": "5012617017109",
//       "description":
//           "Aspirin Dispersible 300mg Tablets dissolve in water for fast absorption and are used to relieve pain, reduce fever, and provide anti-inflammatory effects. Suitable for headaches, colds, and minor aches."
//     },
//     {
//       "name": "Alerid (Cetirizine) Suspension 30ml",
//       "dosage": "30ml",
//       "barcode": "8901117078765",
//       "description":
//           "Alerid Cetirizine 30ml Suspension is an antihistamine used to treat allergy symptoms such as sneezing, itching, watery eyes, and runny nose. Ideal for both children and adults."
//     },
//     {
//       "name": "Loratadine 10mg 10 Tablets (Generic)",
//       "dosage": "10mg",
//       "barcode": "5055144201054",
//       "description":
//           "Loratadine 10mg Tablets are a non-drowsy antihistamine providing 24-hour relief from hay fever, skin allergies, and seasonal allergy symptoms."
//     },
//     {
//       "name": "Omeprazole 20mg 28 Capsules (UK)",
//       "dosage": "20mg",
//       "barcode": "5016695410036",
//       "description":
//           "Omeprazole 20mg Capsules reduce stomach acid and are commonly used for heartburn, acid reflux, and gastric ulcers. Provides long-lasting relief when taken daily."
//     },
//     {
//       "name": "Loperamide 2mg UK 10 Capsules",
//       "dosage": "2mg",
//       "barcode": "5017007388135",
//       "description":
//           "Loperamide 2mg Capsules help control acute diarrhea by slowing bowel movement. Provides fast and effective short-term relief."
//     },
//   ];

//   final firestore = FirebaseFirestore.instance;

//   for (var product in products) {
//     await firestore.collection("product").add(product);
//   }

//   print("Products uploaded successfully!");
// }
