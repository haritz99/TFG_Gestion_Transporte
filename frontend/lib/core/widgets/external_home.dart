import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/theme/app_text_styles.dart';

class ExternalHome extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const ExternalHome({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.headingMd),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                subtitle,
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

