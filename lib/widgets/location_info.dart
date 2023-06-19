import 'package:flutter/material.dart';


class LocationInfo extends StatelessWidget {
  const LocationInfo({
    super.key,
    required this.icon, 
    required this.title,
    required this.description, 
    
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Card(
        margin: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 20),
        elevation: 5,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 15, vertical: 15),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.black,
              ),
              Text(
                "$title :",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2,),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}