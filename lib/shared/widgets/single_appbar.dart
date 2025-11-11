import 'package:flutter/material.dart';

class SingleAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SingleAppbar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      alignment: Alignment.bottomLeft,
      color: const Color(0xFFF8F9FA), // Установлен единый цвет фона
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface, // цвет текста из темы
        ),
      ),
    );
  }
}