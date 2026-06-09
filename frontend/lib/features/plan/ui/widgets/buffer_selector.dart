import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class BufferSelector extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;

  const BufferSelector({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text(
              '$value horas',
              style: AppTextStyles.bodyMd,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}