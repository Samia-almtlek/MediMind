import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../data/models/user_medication_model.dart';
import '../../core/service/tts_service.dart';
class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
@override
void dispose() {
  TTSService.instance.stopIfSpeaking();
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
  title: const Text(
    "My Cabinet",
    style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold),
  ),
  backgroundColor: Colors.white,
  elevation: 0.5,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios,
        color: Colors.black, size: 20),
    onPressed: () => Navigator.pop(context),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.volume_up,
          color: AppColors.primaryBlue),
      onPressed: () async {
        await TTSService.instance.stopIfSpeaking();

        final uid =
            FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        final snapshot =
            await FirebaseFirestore.instance
                .collection('user_medications')
                .where('userId', isEqualTo: uid)
                .where('isActive', isEqualTo: true)
                .get();

        if (snapshot.docs.isEmpty) {
          await TTSService.instance
              .speak("Your cabinet is currently empty.");
          return;
        }

        final meds = snapshot.docs
            .map((doc) =>
                UserMedicationModel.fromFirestore(doc))
            .toList();

        String summary =
            "You have ${meds.length} medications in your cabinet. ";

        for (var med in meds) {
          summary +=
              "${med.name}, dosage ${med.dosage}, "
              "current stock ${med.currentStock}. ";
        }

        await TTSService.instance.speak(summary);
      },
    ),
  ],
),
      body: uid == null
          ? _buildEmptyState()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('user_medications')
                  .where('userId', isEqualTo: uid)
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final meds = snapshot.data!.docs
                    .map((doc) =>
                        UserMedicationModel.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: meds.length,
                  itemBuilder: (context, index) {
                    return _buildMedicineCard(meds[index]);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStockSheet(context),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Stock",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Your cabinet is empty",
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text("Add medication from Treatment Plan",
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(UserMedicationModel med) {

    final int currentStock = med.currentStock;
    final int maxStock =
        med.initialStock == 0 ? 1 : med.initialStock;

    final double progress =
        (currentStock / maxStock).clamp(0.0, 1.0);

    final bool isLowStock =
        currentStock <= med.lowStockThresholdDays;

    Color statusColor = progress < 0.2
        ? Colors.redAccent
        : (progress < 0.5
            ? Colors.orangeAccent
            : AppColors.primaryBlue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(12)),
                child: Icon(Icons.medication,
                    color: statusColor),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(med.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(med.dosage,
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12)),
                    ]),
              ),
              Text("$currentStock/${med.initialStock}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor)),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[100],
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                      statusColor),
            ),
          ),

          const SizedBox(height: 10),

          if (isLowStock)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                "Low stock — please refill",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12),
              ),
            ),

          
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showRefillDialog(
      BuildContext context, UserMedicationModel med) {

    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Refill Medication"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: "Enter quantity"),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {

              final int? amount =
                  int.tryParse(controller.text);

              if (amount == null || amount <= 0)
                return;

              await FirebaseFirestore.instance
                  .collection('user_medications')
                  .doc(med.id)
                  .update({
                'currentStock': FieldValue.increment(amount),
                'initialStock': FieldValue.increment(amount),
              });

              Navigator.pop(context);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showAddStockSheet(BuildContext context) {

    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String? selectedMedicationId;
    UserMedicationModel? selectedMedication;
    final TextEditingController quantityController =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('user_medications')
                  .where('userId', isEqualTo: uid)
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final meds = snapshot.data!.docs
                    .map((doc) =>
                        UserMedicationModel.fromFirestore(doc))
                    .toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Add Medication Stock",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Select Medication",
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      value: selectedMedicationId,
                      items: meds.map((med) {
                        return DropdownMenuItem(
                          value: med.id,
                          child: Text(
                              "${med.name} (${med.dosage})"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedMedicationId = value;
                          selectedMedication =
                              meds.firstWhere(
                                  (element) =>
                                      element.id ==
                                      value);
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: quantityController,
                      keyboardType:
                          TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Quantity to add",
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primaryBlue,
                        minimumSize:
                            const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {

                        final int? amount =
                            int.tryParse(
                                quantityController.text);

                        if (selectedMedication ==
                                null ||
                            amount == null ||
                            amount <= 0) {
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection(
                                'user_medications')
                            .doc(selectedMedication!.id)
                            .update({
                          'currentStock':
                              FieldValue.increment(amount),
                          'initialStock':
                              FieldValue.increment(amount),
                        });

                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Add to Cabinet",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}