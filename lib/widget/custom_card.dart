import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card.filled(
      child: Row(
        children: [
          Column(
            children: [
              Text("Action Item"),
              Text("Subtitle goes here"),
            ],
          )
        ],
      )
    );
  }
}
