import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

class CoreMobileCard extends StatelessWidget {
  final String title;
  final List<MapEntry<String, String>> details;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CoreMobileCard({
    super.key,
    required this.title,
    required this.details,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE8EDF5)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.tableValueStrong),
                Row(
                  children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF8E99AB)),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF8E99AB)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...details.map((detail) => _buildDetailLine(detail.key, detail.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: AppTextStyles.tableValueStrong,
          children: [TextSpan(text: value, style: AppTextStyles.tableValue)],
        ),
      ),
    );
  }
}

