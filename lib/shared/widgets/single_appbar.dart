import 'package:flutter/material.dart';

class SingleAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final bool shrinkLeading;

  const SingleAppbar({
    super.key,
    required this.title,
    this.onBack,
    this.shrinkLeading = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Определяем стиль текста в зависимости от наличия кнопки назад
    final bool hasBackButton = onBack != null;
    
    final TextStyle titleStyle = hasBackButton 
      ? TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        )
      : theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ) ?? TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        );

    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (hasBackButton) ...[
            Material(
              color: Colors.grey[200],
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: Colors.black87,
                padding: EdgeInsets.zero,
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: 12),
          ] else if (shrinkLeading) ...[
            const SizedBox(width: 0),
          ],
        
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                title,
                style: titleStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}