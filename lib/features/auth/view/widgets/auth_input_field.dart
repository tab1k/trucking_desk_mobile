import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.enabled = true,
    this.trailing,
    this.prefix,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final bool enabled;
  final Widget? trailing;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        final fieldValue = state.value ?? '';
        if (controller.text != fieldValue) {
          controller.value = controller.value.copyWith(
            text: fieldValue,
            selection: TextSelection.collapsed(offset: fieldValue.length),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: 56.h),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: Row(
                    children: [
                      if (prefix != null) ...[
                        prefix!,
                        SizedBox(width: 12.w),
                      ] else ...[
                        Icon(
                          icon,
                          color: Colors.grey.shade500,
                          size: 20.w,
                        ),
                        SizedBox(width: 12.w),
                      ],
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onChanged: state.didChange,
                          enabled: enabled,
                          keyboardType: keyboardType,
                          obscureText: obscureText,
                          cursorColor: Colors.blue,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                            isDense: true,
                          ).copyWith(hintText: hintText),
                        ),
                      ),
                      if (trailing != null) ...[
                        SizedBox(width: 12.w),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: EdgeInsets.only(top: 6.h, left: 4.w),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFFB00020),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
