import 'package:flutter/material.dart';

class LocationInfo extends StatefulWidget {
  const LocationInfo({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  _LocationInfoState createState() => _LocationInfoState();
}

class _LocationInfoState extends State<LocationInfo> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        elevation: 5,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: widget.isSelected ? Colors.blue : Colors.white,
        child: InkWell(
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Column(
              children: [
                Icon(
                  widget.icon,
                  color: Colors.black,
                ),
                Text(
                  "${widget.title} :",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isSelected ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color:
                        widget.isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
