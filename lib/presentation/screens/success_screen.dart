import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class SuccessScreen extends StatelessWidget {
  final String medicationName;

  SuccessScreen({required this.medicationName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Groot groen vinkje icoon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primaryBlue,
                  size: 80,
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Great!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "$medicationName has been successfully added to your schedule.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 50),
              // Knop om terug naar huis te gaan
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    // Dit wist alle schermen in de 'stack' en gaat terug naar de eerste pagina (Home)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    "Back to Home",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}