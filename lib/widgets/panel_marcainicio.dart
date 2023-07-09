import 'package:flutter/material.dart';

class PanelMarcaInicio extends StatelessWidget {
  const PanelMarcaInicio({
    super.key, required this.onPressed
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
              left: 25, right: 25, top: 10, bottom: 10),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: onPressed,
            child: const Text('Marcar Inicio')
          ),
        ),
      ),
    );
  }
}
