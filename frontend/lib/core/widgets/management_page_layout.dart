import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ManagementPageLayout extends StatelessWidget {
  final Widget header;
  final Widget table;
  final Future<void> Function()? onMobileLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isMobile;

  const ManagementPageLayout({
    super.key,
    required this.header,
    required this.table,
    this.onMobileLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: AppColors.pageBackground,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (!isMobile || !hasMore || isLoadingMore) return false;
              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 120) {
                onMobileLoadMore?.call();
              }
              return false;
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 12 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 16),
                  table,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

