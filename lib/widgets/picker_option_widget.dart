import 'package:flutter/material.dart';

class PickerOptionWidget extends StatelessWidget {
  const PickerOptionWidget({
    super.key,
    required this.color,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final Color color;

  final String label;

  final IconData icon;

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: _boxDecoration(),
          child: _content(),
        ),
      ),
    );
  }

  /// 🔹 Stil pentru container
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.5), width: 1.5),
    );
  }

  /// 🔹 Conținutul widgetului
  Column _content() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 38.0, color: color),
        const SizedBox(height: 8.0),
        Text(
          label,
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}