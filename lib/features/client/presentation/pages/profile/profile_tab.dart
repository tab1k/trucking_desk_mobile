import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';
import 'package:fura24.kz/router/routes.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  
  // Метод для выхода
  Future<void> _logout() async {
    try {
      final authController = ref.read(authControllerProvider.notifier);
      await authController.logout();
      
      // Перенаправляем на welcome screen
      if (mounted) {
        context.go(AuthRoutes.welcomeScreen);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выходе: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cupertino-style диалог подтверждения выхода
  void _showLogoutDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          'Выход из аккаунта',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите выйти из аккаунта?',
          style: TextStyle(
            fontSize: 16.sp,
          ),
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Отмена',
              style: TextStyle(
                fontSize: 17.sp,
                color: CupertinoColors.systemBlue,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            isDestructiveAction: true,
            child: Text(
              'Выйти',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SingleAppbar(title: 'Профиль'),
      body: CustomScrollView(
        slivers: [
          // Баланс вместо заголовка профиля
          _buildBalanceCard(),

          // Реферальная система
          _buildReferralSection(),

          // Настройки
          _buildSettingsSection(),

          // Поддержка
          _buildSupportSection(),

          // Выход отдельно
          _buildLogoutSection(),

          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildBalanceCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6E41E2), Color(0xFF64B5F6)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64B5F6).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Общий баланс',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '45 000 ₸',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                _BalanceButton(
                  icon: Icons.add,
                  text: 'Пополнить',
                  onTap: () {},
                ),
                SizedBox(width: 12.w),
                _BalanceButton(
                  icon: Icons.arrow_forward,
                  text: 'Перевести',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildReferralSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пригласите друзей',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '500 ₸ на баланс',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              onPressed: () {
                // Действие по приглашению друга
              },
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Text(
                'Пригласить',
                style: TextStyle(
                  color: const Color(0xFF2196F3),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSettingsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            _buildSettingsItem(
              iconPath: 'assets/svg/circle-user.svg',
              title: 'Профиль',
              link: '/my_profile',
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/wallet.svg',
              title: 'Кошелек',
              link: '/my_profile',
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/marker.svg',
              title: 'Мои адреса',
              link: '/my_profile',
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/settings.svg',
              title: 'Настройки',
              link: '/my_profile',
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSupportSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            _buildSettingsItem(
              iconPath: 'assets/svg/help.svg',
              title: 'Помощь',
              link: '/my_profile',
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/terms.svg',
              title: 'Условия использования',
              link: '/my_profile',
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildLogoutSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
        child: CupertinoButton(
          onPressed: _showLogoutDialog,
          color: CupertinoColors.systemRed,
          borderRadius: BorderRadius.circular(12.r),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Выйти из аккаунта',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String iconPath,
    required String title,
    required Widget trailing,
    required String link,
    Color titleColor = Colors.black,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.go(link);
        },
        borderRadius: BorderRadius.circular(0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              SvgPicture.asset(
                iconPath,
                width: 20.w,
                height: 20.w,
                colorFilter: const ColorFilter.mode(
                  CupertinoColors.systemGrey,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: titleColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      height: 0.5,
      color: CupertinoColors.systemGrey5,
    );
  }
}

class _BalanceButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _BalanceButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16.w, color: Colors.white),
                SizedBox(width: 6.w),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
