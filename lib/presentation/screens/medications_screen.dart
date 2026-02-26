import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../utils/app_colors.dart';
import '../../data/models/user_medication_model.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          "My Medications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: uid == null
          ? _buildEmptyState()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('user_medications')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final List<UserMedicationModel> meds = snapshot.data!.docs
                    .map((doc) => UserMedicationModel.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meds.length,
                  itemBuilder: (context, index) =>
                      _buildTreatmentCard(meds[index], context),
                );
              },
            ),
    );
  }

  Widget _buildTreatmentCard(UserMedicationModel med, BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime checkDate = med.endDate ?? med.startDate;

    // Normalize dates to compare only Day/Month/Year
    final bool isDatePassed = today.isAfter(
        DateTime(checkDate.year, checkDate.month, checkDate.day)
            .add(const Duration(days: 1)));
    final bool isActive = !isDatePassed && med.isActive;
    final bool isLowStock = med.currentStock <= med.lowStockThresholdDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightTeal.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.medication_liquid, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 16),

              // Medication Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Dosage: ${med.dosage}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),

                    // Stock Status
                    Row(
                      children: [
                        Icon(
                          isLowStock
                              ? Icons.warning_amber_rounded
                              : Icons.inventory_2_outlined,
                          size: 16,
                          color: isLowStock ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Stock: ${med.currentStock} units",
                          style: TextStyle(
                            color: isLowStock ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isActive),
            ],
          ),
          const Divider(height: 24),

          // Refill Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showRefillDialog(context, med),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Refill Medication"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRefillDialog(BuildContext context, UserMedicationModel med) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Refill ${med.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "How many units are you adding to your current stock?"),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final int? newAmount = int.tryParse(controller.text);
                if (newAmount == null || newAmount <= 0) return;

                await FirebaseFirestore.instance
                    .collection('user_medications')
                    .doc(med.id)
                    .update({
                  'currentStock': FieldValue.increment(newAmount),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Stock updated successfully!")),
                );
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? "Active" : "Finished",
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No medications found",
            style: TextStyle(
                fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
