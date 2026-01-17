import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fura24.kz/core/network/dadata_service.dart';

class AddressAutocompleteField extends StatelessWidget {
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.city,
    this.isRequired = false,
    this.icon = Icons.place_outlined,
  });

  final TextEditingController controller;
  final String label;
  final String? city;
  final bool isRequired;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            '$label${isRequired ? ' *' : ''}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        TypeAheadField<String>(
          controller: controller,
          builder: (context, controller, focusNode) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: city != null && city!.isNotEmpty
                    ? 'Адрес в городе $city'
                    : 'Улица, дом',
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                prefixIcon: Icon(icon, size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              validator: isRequired
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Это поле обязательно';
                      }
                      return null;
                    }
                  : null,
            );
          },
          suggestionsCallback: (pattern) async {
            return await daDataService.getSuggestions(pattern, city: city);
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              leading: Icon(Icons.location_on, size: 18.w, color: Colors.grey),
              title: Text(suggestion, style: TextStyle(fontSize: 14.sp)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            );
          },
          onSelected: (suggestion) {
            controller.text = suggestion;
          },
          emptyBuilder: (context) => const SizedBox.shrink(),
          hideOnEmpty: true,
          decorationBuilder: (context, child) {
            return Material(
              type: MaterialType.card,
              elevation: 4,
              borderRadius: BorderRadius.circular(12.r),
              child: child,
            );
          },
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
