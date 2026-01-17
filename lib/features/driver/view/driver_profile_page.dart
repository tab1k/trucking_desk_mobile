import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';
import 'package:fura24.kz/features/driver/view/driver_settings_page.dart';
import 'package:fura24.kz/features/profile/view/privacy_policy_page.dart';
import 'package:fura24.kz/features/profile/view/user_agreement_page.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:fura24.kz/router/utils/navigation_utils.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';

class DriverProfilePage extends ConsumerStatefulWidget {
  const DriverProfilePage({super.key});

  @override
  ConsumerState<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends ConsumerState<DriverProfilePage> {
  void _copyReferral(String? code) {
    final trimmed = code?.trim() ?? '';
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('driver_profile.referral.unavailable'))),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: trimmed));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('driver_profile.referral.copied'))),
    );
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
      if (!profileState.isLoading && profileState.user == null) {
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
  }

  Future<void> _logout() async {
    try {
      final authController = ref.read(authControllerProvider.notifier);
      await authController.logout();

      if (mounted) {
        context.go(AuthRoutes.welcomeScreen);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tr('driver_profile.logout.error')}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          tr('driver_profile.logout.title'),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          tr('driver_profile.logout.confirm'),
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              tr('driver_profile.logout.cancel'),
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
              tr('driver_profile.logout.submit'),
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildVerificationBanner(UserModel? user) {
    final status = user?.verificationStatus ?? 'PENDING';
    String title;
    Color color;
    String? message;
    VoidCallback? onTap;

    switch (status) {
      case 'APPROVED':
        title = 'driver_profile.verification.status.approved'.tr();
        color = Colors.green;
        break;
      case 'IN_REVIEW':
        title = 'driver_profile.verification.status.in_review'.tr();
        color = Colors.orange;
        message = 'driver_profile.verification.message.in_review'.tr();
        break;
      case 'REJECTED':
        title = 'driver_profile.verification.status.rejected'.tr();
        color = Colors.red;
        message = user?.verificationRejectionReason?.isNotEmpty == true
            ? user!.verificationRejectionReason
            : 'driver_profile.verification.message.rejected_default'.tr();
        onTap = () => context.go(DriverRoutes.verification);
        break;
      default:
        title = 'driver_profile.verification.status.required'.tr();
        color = Colors.blue;
        message = 'driver_profile.verification.message.required'.tr();
        onTap = () => context.go(DriverRoutes.verification);
    }

    return SliverToBoxAdapter(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user, color: color, size: 20.w),
                  SizedBox(width: 6.w),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              if (message != null) ...[
                SizedBox(height: 6.h),
                Text(
                  message,
                  style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final balanceText = user != null
        ? _balanceFormat.format(user.balance)
        : '—';
    final isVerified = user?.verificationStatus == 'APPROVED';
    final verificationBanner = _buildVerificationBanner(user);
    final referralCode = (user?.referralCode?.trim().isNotEmpty ?? false)
        ? user!.referralCode!
        : '—';

    if (profileState.isLoading && user == null) {
      return Scaffold(
        appBar: SingleAppbar(title: tr('driver_profile.title')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profileState.error != null && user == null) {
      return Scaffold(
        appBar: SingleAppbar(title: tr('driver_profile.title')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('driver_profile.error_load')),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadProfile(),
                child: Text(tr('driver_profile.retry')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: SingleAppbar(title: tr('driver_profile.title')),
      body: CustomScrollView(
        slivers: [
          _buildBalanceCard(balanceText),
          isVerified ? _buildReferralSection(referralCode) : verificationBanner,
          _buildSettingsSection(),
          _buildTariffsSection(),
          _buildBusinessSection(),
          _buildSupportSection(),
          _buildSocialLinksSection(),
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
              tr('driver_profile.balance.title'),
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
                  text: tr('driver_profile.balance.top_up'),
                  onTap: () => context.push(ProfileRoutes.wallet),
                ),
                SizedBox(width: 12.w),
                _BalanceButton(
                  icon: Icons.history,
                  text: 'driver_profile.balance.history'.tr(),
                  onTap: () => context.push(ProfileRoutes.wallet),
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
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('driver_profile.referral.title'),
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
                          tr('driver_profile.referral.copy'),
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
              title: tr('driver_profile.settings.profile'),
              link: ProfileRoutes.my_profile,
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/wallet.svg',
              title: tr('driver_profile.settings.wallet'),
              link: ProfileRoutes.wallet,
              onTap: () => context.push(ProfileRoutes.wallet),
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/settings.svg',
              title: tr('driver_profile.settings.settings'),
              link: ProfileRoutes.settings,
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
              onTap: () {
                NavigationUtils.navigateWithBottomSheetAnimation(
                  context,
                  const DriverSettingsPage(),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/help.svg',
              title: tr('driver_profile.settings.help'),
              link: '',
              onTap: () => _showSupportSheet(
                title: tr('driver_profile.settings.help'),
                description: tr('driver_profile.support.help_body'),
                contacts: const [
                  _SupportContact(
                    svgAsset: 'assets/svg/whatsapp.svg',
                    label: 'WhatsApp',
                    value: '+7778 272 9845',
                  ),
                  _SupportContact(
                    icon: Icons.telegram,
                    label: 'Telegram',
                    value: '@TruckingDesk_bot',
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

  SliverToBoxAdapter _buildTariffsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: _buildSettingsItem(
          iconPath: 'assets/svg/ticket.svg',
          title: tr('driver_profile.balance.tariffs'),
          link: DriverRoutes.tariffs,
          onTap: () => context.push(DriverRoutes.tariffs),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'driver_profile.verification.active_status'.tr(),
                style: TextStyle(
                  color: Colors.green, // Active color
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildBusinessSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            _buildSettingsItem(
              iconPath: 'assets/svg/business.svg',
              title: tr('driver_profile.balance.business'),
              link: DriverRoutes.businessServices,
              onTap: () {
                context.push(DriverRoutes.businessServices);
              },
              trailing: Icon(
                Icons.chevron_right,
                size: 20.w,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            _buildDivider(),
            _buildSettingsItem(
              iconPath: 'assets/svg/hand.svg',
              title: tr('driver_profile.balance.partner'),
              link: DriverRoutes.becomePartner,
              onTap: () {
                context.push(DriverRoutes.becomePartner);
              },
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
              title: tr('driver_profile.settings.user_agreement'),
              link: '',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UserAgreementPage(
                    titleKey: 'driver_profile.settings.user_agreement',
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
              title: tr('driver_profile.settings.privacy'),
              link: '',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyPage(
                    titleKey: 'driver_profile.settings.privacy',
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
                    tr('driver_profile.logout.button'),
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
              '${tr('driver_profile.app_version')}: ${_appVersion ?? '—'} • ZIZ.INC • by tab1kkz',
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
    required String link,
    Color titleColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => context.go(link),
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
                  return Container(
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
                                  color: Theme.of(context).colorScheme.primary,
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
                    tr('driver_profile.support.close'),
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

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('common.error'))));
    }
  }
}

class _SupportContact {
  const _SupportContact({
    this.icon,
    this.svgAsset,
    required this.label,
    required this.value,
  });

  final IconData? icon;
  final String? svgAsset;
  final String label;
  final String value;
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

class _BalanceButton extends StatelessWidget {
  const _BalanceButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

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
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
