import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  bool _isSubmitting = false;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileProvider).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _pickedImageBytes = bytes;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(profileProvider).user;
    final form = _formKey.currentState;
    if (form == null || user == null) return;
    if (!form.validate()) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final hasAvatarChange = _pickedImage != null;

    final updates = <String, dynamic>{};
    if (firstName != user.firstName) updates['first_name'] = firstName;
    if (lastName != user.lastName) updates['last_name'] = lastName;
    if (email != (user.email ?? '')) {
      updates['email'] = email.isEmpty ? null : email;
    }

    if (updates.isEmpty && !hasAvatarChange) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('profile_edit.no_changes'))));
      return;
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    await ref
        .read(profileProvider.notifier)
        .updateProfile(
          updates,
          avatarFile: hasAvatarChange ? _pickedImage : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final updatedState = ref.read(profileProvider);
    final errorMessage = updatedState.error;
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage.isEmpty ? tr('profile_edit.error') : errorMessage,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('profile_edit.success'))));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          tr('profile.title'),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Material(
            color: Colors.grey[200],
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              color: Colors.black87,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            onPressed: _isSubmitting ? null : _submit,
            child:
                _isSubmitting
                    ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      tr('profile_edit.save'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ],
      ),
      body:
          user == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarPicker(user),
                      SizedBox(height: 20.h),
                      _buildField(
                        label: tr('profile_edit.first_name'),
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr('profile_edit.first_name_required');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildField(
                        label: tr('profile_edit.last_name'),
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 16.h),
                      _buildField(
                        label: tr('profile_edit.email'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final emailRegex = RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          );
                          if (!emailRegex.hasMatch(text)) {
                            return tr('profile_edit.email_invalid');
                          }
                          return null;
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPicker(UserModel user) {
    final avatarUrl = user.avatar;
    final displayName = user.displayName;
    ImageProvider? provider;
    if (_pickedImageBytes != null && _pickedImageBytes!.isNotEmpty) {
      provider = MemoryImage(_pickedImageBytes!);
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      provider = NetworkImage(avatarUrl);
    }

    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _isSubmitting ? null : _pickImage,
            child: CircleAvatar(
              radius: 46.r,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: provider,
              child:
                  provider == null
                      ? Text(
                        _initials(displayName),
                        style: TextStyle(
                          fontSize: 24.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        CupertinoButton(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          onPressed: _isSubmitting ? null : _pickImage,
          child: Text(
            tr('profile_edit.change_photo'),
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      final parts = trimmedName.split(RegExp(r'\s+'));
      final buffer = StringBuffer();
      for (final part in parts) {
        if (part.isEmpty) continue;
        buffer.write(part[0]);
        if (buffer.length >= 2) break;
      }
      final result = buffer.toString();
      if (result.isNotEmpty) {
        return result.toUpperCase();
      }
    }
    return '?';
  }
}
