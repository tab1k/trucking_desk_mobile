import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';

class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key});

  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage> {
  final _deletePasswordController = TextEditingController();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(profileProvider);
      if (!state.isLoading) {
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _deletePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 60.h,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Material(
            color: Colors.grey[200],
            shape: const CircleBorder(),
            child: IconButton(
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.arrow_back, size: 20),
              color: Colors.black87,
              padding: EdgeInsets.all(10.w),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                final role = user?.role.trim().toUpperCase();
                final isDriver = role == 'DRIVER';
                context.go(isDriver ? AppRoutes.driverHome : AppRoutes.home);
              },
            ),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Text(
            tr('profile.title'),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            minSize: 0,
            onPressed: () {
              context.push(ProfileRoutes.edit_profile);
            },
            child: Text(
              tr('profile_edit.edit'),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF007AFF),
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(profileProvider.notifier).loadProfile(),
        child: Builder(
          builder: (context) {
            if (profileState.isLoading && user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (profileState.error != null && user == null) {
              return Center(
                child: _ErrorView(
                  message: profileState.error!,
                  onRetry:
                      () => ref.read(profileProvider.notifier).loadProfile(),
                ),
              );
            }

            if (user == null) {
              return Center(child: Text(tr('profile.unavailable')));
            }

            final displayName =
                user.displayName.trim().isEmpty
                    ? tr('profile.user_placeholder')
                    : user.displayName;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Верхняя секция с аватаром и основной информацией
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Column(
                      children: [
                        _ProfileAvatar(user: user),
                        SizedBox(height: 16.h),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _getRoleDisplayName(user.role),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Информационные карточки
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(
                          context,
                          title: tr('profile.contact.title'),
                          items: [
                            _buildInfoItem(
                              context,
                              svgAsset: 'assets/svg/phone-call.svg',
                              title: tr('profile.contact.phone'),
                              value:
                                  user.phoneNumber.isEmpty
                                      ? tr('profile.contact.empty')
                                      : user.phoneNumber,
                            ),
                            _buildInfoItem(
                              context,
                              svgAsset: 'assets/svg/envelope.svg',
                              title: tr('profile.contact.email'),
                              value: user.email ?? tr('profile.contact.empty'),
                            ),
                          ],
                        ),

                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isDeleting ? null : _showDeleteAccountSheet,
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 18.w,
                            ),
                            label: Text(
                              tr('profile.delete_account'),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.shade400,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteAccountSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (modalContext) {
        bool obscure = true;
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: 16.h,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    16.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    tr('profile.delete.title'),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    tr('profile.delete.prompt'),
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: _deletePasswordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: tr('profile.delete.password'),
                      hintText: tr('profile.delete.password'),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF00B2FF),
                          width: 1.2,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setStateModal(() {
                          obscure = !obscure;
                        }),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isDeleting
                              ? null
                              : () => Navigator.of(modalContext).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            tr('profile.delete.cancel'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CupertinoColors.systemRed,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isDeleting
                              ? null
                              : () => _deleteAccount(
                                    _deletePasswordController.text,
                                    modalContext,
                                  ),
                          child: _isDeleting
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  tr('profile.delete.confirm'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.sp,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAccount(String password, BuildContext modalContext) async {
    if (password.trim().isEmpty) {
      ScaffoldMessenger.of(modalContext).showSnackBar(
        SnackBar(content: Text(tr('profile.delete.error_empty'))),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final success = await ref.read(authControllerProvider.notifier).deleteAccount(
          password: password,
        );

    if (!mounted) return;
    setState(() {
      _isDeleting = false;
    });
    _deletePasswordController.clear();

    if (success) {
      Navigator.of(modalContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('profile.delete.success'))),
      );
      context.go(AuthRoutes.welcomeScreen);
    } else {
      final error =
          authErrorMessage(ref.read(authControllerProvider)) ??
          tr('profile.delete.error_failed');
      ScaffoldMessenger.of(modalContext).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}

String _getInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isNotEmpty) {
    final parts = trimmed.split(RegExp(r'\s+'));
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

String _getRoleDisplayName(String role) {
  final normalized = role.trim().toUpperCase();
  if (normalized.isEmpty) {
    return tr('profile.role.unknown');
  }

  switch (normalized) {
    case 'SENDER':
      return tr('profile.role.sender');
    case 'DRIVER':
      return tr('profile.role.driver');
    default:
      return role;
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatar;
    final displayName = user.displayName;
    ImageProvider? avatarProvider;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarProvider = NetworkImage(avatarUrl);
    }

    return CircleAvatar(
      radius: 40.r,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: avatarProvider,
      child:
          avatarProvider == null
              ? Text(
                _getInitials(displayName),
                style: TextStyle(
                  fontSize: 24.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
    );
  }
}

Widget _buildInfoSection(
  BuildContext context, {
  required String title,
  required List<Widget> items,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
      SizedBox(height: 12.h),
      ...items,
    ],
  );
}

Widget _buildInfoItem(
  BuildContext context, {
  required String title,
  required String value,
  String? svgAsset,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: 8.h),
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
      ),
    ),
    child: Row(
      children: [
        if (svgAsset != null)
          SvgPicture.asset(
            svgAsset,
            width: 20.w,
            height: 20.w,
            fit: BoxFit.scaleDown,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),

        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48.w,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16.h),
          Text(
            tr('profile.error.title'),
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(onPressed: onRetry, child: Text(tr('common.retry'))),
        ],
      ),
    );
  }
}
