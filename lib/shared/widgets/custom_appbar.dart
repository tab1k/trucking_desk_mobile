import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      floating: true,
      snap: false,
      expandedHeight: 80,
      collapsedHeight: 80,
      toolbarHeight: 80,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
        ),
      ),
      title: SafeArea(
        bottom: false, // Важно: убираем отступ снизу
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Табигат Карбаев',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1F),
                      ),
                    ),
                    Text(
                      '@tab1k',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6C7278),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            InkWell(
              onTap: () {
                // Заглушка для уведомлений
              },
              child: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 28,
                    color: Color(0xFF1A1D1F),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}