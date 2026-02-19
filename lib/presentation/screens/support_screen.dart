import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // Lijst met FAQ data
  final List<Map<String, String>> _faqs = [
    {
      "question": "How do I add a new medicine?",
      "answer": "Navigate to the 'Medications' screen from your dashboard and tap the '+' button. You can then scan your medication or add it manually."
    },
    {
      "question": "Is my data safe with MediMind?",
      "answer": "Yes, your medical data is encrypted and stored locally via Hive. Syncing with Firebase happens over a secure connection following GDPR protocols."
    },
    {
      "question": "Can I share my list with my doctor?",
      "answer": "Absolutely. Go to 'Privacy & Data' and select 'Data Export'. This generates a summary that you can share via email or PDF."
    },
    {
      "question": "How do notification alerts work?",
      "answer": "MediMind sends local push notifications based on the schedule you set. Ensure that 'Medication Reminders' is enabled in your settings."
    },
  ];

  // Houdt bij welke FAQ opengeklapt is
  int? _expandedIndex;

  void _showContactForm() {
    final formKey = GlobalKey<FormState>();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("Contact Support", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextFormField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Describe your problem or question...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (val) => val!.isEmpty ? "Please enter a message" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Message sent! We will contact you soon."), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text("Send Message", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("Support", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.headset_mic_outlined, size: 40, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            const Text("How can we help?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Find answers below or reach out to us.", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 30),
            
            // Dynamische FAQ Lijst
            ...List.generate(_faqs.length, (index) => _buildExpandableFAQ(index)),
            
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _showContactForm,
              child: const Text("Open Support Ticket", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFAQ(int index) {
    bool isExpanded = _expandedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isExpanded ? AppColors.primaryBlue : Colors.grey.shade200),
        boxShadow: [if (isExpanded) BoxShadow(color: AppColors.primaryBlue.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(_faqs[index]['question']!, 
              style: TextStyle(fontWeight: FontWeight.bold, color: isExpanded ? AppColors.primaryBlue : Colors.black)),
            trailing: Icon(isExpanded ? Icons.remove : Icons.add, color: AppColors.primaryBlue),
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(_faqs[index]['answer']!, style: TextStyle(color: Colors.grey[700], height: 1.5)),
            ),
        ],
      ),
    );
  }
}