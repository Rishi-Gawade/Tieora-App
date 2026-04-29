import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  final double size;

  const AppLoader({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}