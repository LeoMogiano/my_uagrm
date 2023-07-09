import 'package:flutter/material.dart';


class TrayectoriaInfo extends StatelessWidget {
  const TrayectoriaInfo({
    super.key, this.child,
  });

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: IntrinsicHeight(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
          shadowColor: Colors.black,
          margin:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            margin:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            width: double.infinity,
            color: Colors.white,
            child: child ?? const SizedBox()
          ),
        ),
      ),
    );
  }
}
