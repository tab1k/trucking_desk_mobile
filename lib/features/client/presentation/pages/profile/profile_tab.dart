import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';
import 'package:fura24.kz/features/reviews/view/my_reviews_page.dart';
import 'package:fura24.kz/features/profile/view/privacy_policy_page.dart';
import 'package:fura24.kz/features/profile/view/user_agreement_page.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';
import 'package:fura24.kz/router/routes.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  final TextEditingController _deletePasswordController =
      TextEditingController();
  bool _isDeleting = false;

  void _copyReferral(String? code) {
    final trimmed = code?.trim() ?? '';
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('profile.referral.unavailable'))),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: trimmed));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('profile.referral.copied'))));
  }

  Future<void> _openContact(_SupportContact contact) async {
    final uriString = contact.url ?? _buildContactUri(contact.value);
    if (uriString == null) return;
    final uri = Uri.parse(uriString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String? _buildContactUri(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('+')) {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
      return 'tel:$digits';
    }
    if (trimmed.startsWith('@')) {
      final handle = trimmed.substring(1);
      if (handle.isEmpty) return null;
      return 'https://t.me/$handle';
    }
    if (trimmed.startsWith('http')) return trimmed;
    return null;
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('common.error'))));
    }
  }

  final _balanceFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₸',
    decimalDigits: 0,
  );
  String? _appVersion;

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = info.version;
      });
    } catch (_) {
      // Ignore errors and leave version unset.
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(profileProvider);
      if (!profileState.isLoading) {
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _deletePasswordController.dispose();
    super.dispose();
  }

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
            content: Text(tr('profile_tab.logout_error', args: [e.toString()])),
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
          tr('profile_tab.logout_title'),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          tr('profile_tab.logout_question'),
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              tr('common.cancel'),
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
              tr('profile_tab.logout'),
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(
    String password,
    BuildContext modalContext,
  ) async {
    if (password.trim().isEmpty) {
      ScaffoldMessenger.of(
        modalContext,
      ).showSnackBar(const SnackBar(content: Text('Введите пароль')));
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(password: password);

    if (!mounted) return;
    setState(() {
      _isDeleting = false;
    });
    _deletePasswordController.clear();

    if (success) {
      Navigator.of(modalContext).pop(); // закрыть sheet
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Аккаунт удален')));
      context.go(AuthRoutes.welcomeScreen);
    } else {
      final error =
          authErrorMessage(ref.read(authControllerProvider)) ??
          'Не удалось удалить аккаунт';
      ScaffoldMessenger.of(
        modalContext,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
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
        return Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16.h,
            top: 20.h,
          ),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Удаление аккаунта',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Введите пароль, чтобы удалить аккаунт. Действие необратимо.',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: _deletePasswordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setStateModal(() => obscure = !obscure),
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
                          child: const Text('Отмена'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CupertinoColors.systemRed,
                          ),
                          onPressed: _isDeleting
                              ? null
                              : () => _deleteAccount(
                                  _deletePasswordController.text,
                                  modalContext,
                                ),
                          child: _isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Удалить'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final balanceText = user != null
        ? _balanceFormat.format(user.balance)
        : '—';
    final referralCode = (user?.referralCode?.trim().isNotEmpty ?? false)
        ? user!.referralCode!
        : '—';

    if (profileState.isLoading && user == null) {
      return Scaffold(
        appBar: SingleAppbar(title: tr('profile_tab.title')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profileState.error != null && user == null) {
      return Scaffold(
        appBar: SingleAppbar(title: tr('profile_tab.title')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('profile_tab.error')),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadProfile(),
                child: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: SingleAppbar(title: tr('profile_tab.title')),
      body: CustomScrollView(
        slivers: [
          // Баланс вместо заголовка профиля
          _buildBalanceCard(balanceText),

          // Реферальная система
          _buildReferralSection(referralCode),

          // Настройки
          _buildSettingsSection(),

          // Поддержка
          _buildSupportSection(),

          // Соцсети
          _buildSocialLinksSection(),

          // Выход отдельно
          _buildLogoutSection(),

          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildBalanceCard(String balanceText) {
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
              tr('profile_tab.balance_title'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              balanceText,
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
                  text: tr('profile_tab.top_up'),
                  onTap: () {},
                ),
                SizedBox(width: 12.w),
                _BalanceButton(
                  icon: Icons.history,
                  text: tr('profile_tab.history'),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildReferralSection(String referralCode) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        padding: EdgeInsets.all(12.w),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('profile_tab.referral.title'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      referralCode,
                      style: TextStyle(
                        color: const Color(0xFF2196F3),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copyReferral(referralCode),
                    child: Row(
                      children: [
                        Icon(
                          Icons.copy_outlined,
                          color: const Color(0xFF2196F3),
                          size: 18.w,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          tr('profile_tab.referral.copy'),
                          style: TextStyle(
                            color: const Color(0xFF2196F3),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
              title: tr('profile_tab.settings.profile'),
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
              title: tr('profile_tab.settings.wallet'),
              link: ProfileRoutes.wallet,
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/comment-dots.svg',
              title: tr('profile.my_reviews'),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MyReviewsPage())),
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/settings.svg',
              title: tr('profile_tab.settings.settings'),
              link: ProfileRoutes.settings,
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/help.svg',
              title: tr('profile_tab.settings.help'),
              onTap: () => _showSupportSheet(
                title: tr('profile_tab.settings.help'),
                description: tr('profile_tab.support.help_body'),
                contacts: const [
                  _SupportContact(
                    svgAsset: 'assets/svg/whatsapp.svg',
                    label: 'WhatsApp',
                    value: '+7778 272 9845',
                    url: 'https://wa.me/77782729845',
                  ),
                  _SupportContact(
                    icon: Icons.telegram,
                    label: 'Telegram',
                    value: '@TruckingDesk_bot',
                    url: 'https://t.me/TruckingDesk_bot',
                  ),
                ],
              ),
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
              iconPath: 'assets/svg/sogl.svg',
              title: tr('profile_tab.settings.user_agreement'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UserAgreementPage(
                    titleKey: 'profile_tab.settings.user_agreement',
                  ),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/terms.svg',
              title: tr('profile_tab.settings.privacy'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyPage(
                    titleKey: 'profile_tab.settings.privacy',
                  ),
                ),
              ),
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

  SliverToBoxAdapter _buildSocialLinksSection() {
    final links = [
      _SocialLink(
        label: 'Instagram',
        url: 'https://www.instagram.com/p/DA9LfNNuOE0/?igsh=d2s0b3V5Zm1qdGpi',
        svgAsset: 'assets/svg/instagram.svg',
        color: const Color(0xFFE1306C),
      ),
      _SocialLink(
        label: 'WhatsApp',
        url: 'https://www.instagram.com/p/DA9LfNNuOE0/?igsh=d2s0b3V5Zm1qdGpi',
        svgAsset: 'assets/svg/whatsapp.svg',
        color: const Color(0xFF25D366),
      ),
      _SocialLink(
        label: 'Facebook',
        url:
            'https://www.facebook.com/people/Trucking-Desk/61566942634807/?mibextid=LQQJ4d&rdid=CbMf6g4FktRAJGxp&share_url=https%3A%2F%2Fwww.facebook.com%2Fshare%2F3LoXeSe22qYaH5bS%2F%3Fmibextid%3DLQQJ4d',
        icon: Icons.facebook,
        color: const Color(0xFF1877F2),
      ),
      _SocialLink(
        label: 'Telegram',
        url: 'https://t.me/TruckingDesk_bot',
        svgAsset: 'assets/svg/telegram.svg',
        color: const Color(0xFF0088CC),
      ),
      _SocialLink(
        label: 'TikTok',
        url: 'https://www.tiktok.com/@truckingdesk?_t=8qVCKlJhCSl&_r=1',
        svgAsset: 'assets/svg/tiktok-circle.svg',
        color: Colors.black,
      ),
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('profile_tab.socials_title'),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: links
                    .map(
                      (link) => _SocialButton(
                        link: link,
                        onTap: () => _openLink(link.url),
                      ),
                    )
                    .toList(),
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
        child: Column(
          children: [
            CupertinoButton(
              onPressed: _showLogoutDialog,
              color: CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(12.r),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr('profile_tab.logout'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '${tr('profile_tab.app_version')}: ${_appVersion ?? '—'} • ZIZ.INC • by tab1kkz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String iconPath,
    required String title,
    required Widget trailing,
    String? link,
    VoidCallback? onTap,
    Color titleColor = Colors.black,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? (link != null ? () => context.go(link) : null),
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

  void _showSupportSheet({
    required String title,
    required String description,
    List<_SupportContact> contacts = const [],
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        final padding = bottomPadding == 0 ? 24.h : bottomPadding + 12.h;

        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              if (contacts.isNotEmpty) ...[
                SizedBox(height: 14.h),
                ...contacts.asMap().entries.map((entry) {
                  final contact = entry.value;
                  final isLast = entry.key == contacts.length - 1;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () => _openContact(contact),
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: contact.svgAsset != null
                                  ? SvgPicture.asset(
                                      contact.svgAsset!,
                                      width: 18.w,
                                      height: 18.w,
                                      colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.primary,
                                        BlendMode.srcIn,
                                      ),
                                    )
                                  : Icon(
                                      contact.icon ??
                                          Icons.chat_bubble_outline_rounded,
                                      size: 18.w,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.label,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  contact.value,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    tr('profile_tab.support.close'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

class _SupportContact {
  const _SupportContact({
    this.icon,
    this.svgAsset,
    required this.label,
    required this.value,
    this.url,
  });

  final IconData? icon;
  final String? svgAsset;
  final String label;
  final String value;
  final String? url;
}

class _SocialLink {
  const _SocialLink({
    required this.label,
    required this.url,
    this.icon,
    this.svgAsset,
    required this.color,
  });

  final String label;
  final String url;
  final IconData? icon;
  final String? svgAsset;
  final Color color;
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.link, required this.onTap});

  final _SocialLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: link.color.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[200]!),
        ),
        alignment: Alignment.center,
        child: link.svgAsset != null
            ? SvgPicture.asset(
                link.svgAsset!,
                width: 22.w,
                height: 22.w,
                colorFilter: ColorFilter.mode(link.color, BlendMode.srcIn),
              )
            : Icon(link.icon, size: 20.w, color: link.color),
      ),
    );
  }
}
