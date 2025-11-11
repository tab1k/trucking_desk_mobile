import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';

class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key});

  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(profileProvider);
      if (!state.isLoading && state.user == null) {
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
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
              icon: const Icon(Icons.arrow_back, size: 20),
              color: Colors.black87,
              padding: EdgeInsets.zero,
              onPressed: () => context.go(AppRoutes.home),
            ),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Text(
            'Профиль',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        )
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
                  onRetry: () => ref.read(profileProvider.notifier).loadProfile(),
                ),
              );
            }

            if (user == null) {
              return const Center(child: Text('Профиль пользователя недоступен'));
            }

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
                        CircleAvatar(
                          radius: 40.r,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            _getInitials(user.username),
                            style: TextStyle(
                              fontSize: 24.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          user.username.isEmpty ? 'Пользователь' : user.username,
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          title: 'Контактная информация',
                          items: [
                            _buildInfoItem(
                              context,
                              svgAsset: 'assets/svg/phone-call.svg',
                              title: 'Телефон',
                              value: user.phoneNumber.isEmpty ? 'Не указан' : user.phoneNumber,
                            ),
                            _buildInfoItem(
                              context,
                              svgAsset: 'assets/svg/envelope.svg',
                              title: 'Email',
                              value: user.email ?? 'Не указан',
                            ),
                          ],
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

  
}

String _getInitials(String username) {
  final name = username.trim();
  if (name.isNotEmpty) {
    final parts = name.split(RegExp(r'\s+'));
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
    return 'Роль не указана';
  }

  switch (normalized) {
    case 'SENDER':
      return 'Отправитель';
    case 'DRIVER':
      return 'Водитель';
    default:
      return role;
  }
}

Widget _buildInfoSection(BuildContext context, {
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
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
      required this.message,
      required this.onRetry,
    });

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
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
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
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
  }
