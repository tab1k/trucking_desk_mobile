import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AuthRole { client, driver }

class AuthRoleToggle extends StatelessWidget {
  const AuthRoleToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AuthRole value;
  final ValueChanged<AuthRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: AuthRole.values.map((role) {
          final bool isSelected = value == role;
          final Color selectedColor = theme.colorScheme.primary;
          final Color textColor = isSelected ? Colors.white : Colors.black87;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  onChanged(role);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  _roleLabel(role),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _roleLabel(AuthRole role) {
    switch (role) {
      case AuthRole.client:
        return 'Клиент';
      case AuthRole.driver:
        return 'Водитель';
    }
  }
}
