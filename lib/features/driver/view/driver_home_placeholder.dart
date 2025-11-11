import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';
import 'package:fura24.kz/router/routes.dart';

class DriverHomePlaceholderPage extends ConsumerStatefulWidget {
  const DriverHomePlaceholderPage({super.key});

  @override
  ConsumerState<DriverHomePlaceholderPage> createState() =>
      _DriverHomePlaceholderPageState();
}

class _DriverHomePlaceholderPageState
    extends ConsumerState<DriverHomePlaceholderPage> {
  static const Color _primaryColor = Color(0xFF0E4ECF);
  static const Color _accentColor = Color(0xFF5D8BFF);
  static const Color _backgroundColor = Color(0xFFF2F4F8);
  static const Color _cardBorderColor = Color(0xFFE3E8F4);
  static const double _cardRadius = 22;

  static const List<_DriverStat> _stats = [
    _DriverStat(
      title: 'В работе',
      value: '2 рейса',
      trendLabel: '1 новый сегодня',
      isPositive: true,
      icon: Icons.assignment_outlined,
    ),
    _DriverStat(
      title: 'Доставлено',
      value: '18 за месяц',
      trendLabel: '+3 к плану',
      isPositive: true,
      icon: Icons.check_circle_outline,
    ),
    _DriverStat(
      title: 'Рейтинг',
      value: '4.9',
      trendLabel: '5 отзывов',
      isPositive: true,
      icon: Icons.star_outline,
    ),
    _DriverStat(
      title: 'Без задержек',
      value: '92%',
      trendLabel: '−1% на прошлой неделе',
      isPositive: false,
      icon: Icons.timelapse_outlined,
    ),
  ];

  static const List<_DriverQuickAction> _quickActions = [
    _DriverQuickAction(
      icon: Icons.play_circle_outline,
      label: 'Отметить выезд',
    ),
    _DriverQuickAction(
      icon: Icons.fact_check_outlined,
      label: 'Статус загрузки',
    ),
    _DriverQuickAction(
      icon: Icons.local_gas_station_outlined,
      label: 'Добавить расход',
    ),
    _DriverQuickAction(icon: Icons.photo_camera_outlined, label: 'Фото отчёт'),
    _DriverQuickAction(
      icon: Icons.chat_bubble_outline,
      label: 'Связаться с диспетчером',
    ),
    _DriverQuickAction(
      icon: Icons.route_outlined,
      label: 'Маршрут в навигатор',
    ),
  ];

  static const List<_DriverTimelineEvent> _timeline = [
    _DriverTimelineEvent(
      time: '08:30',
      title: 'Погрузка завершена',
      description: 'Склад «Логистик» · Алматы',
      status: _DriverTimelineStatus.completed,
    ),
    _DriverTimelineEvent(
      time: '10:45',
      title: 'Контрольная точка',
      description: 'Пост «Каскелен» · Всё по графику',
      status: _DriverTimelineStatus.completed,
    ),
    _DriverTimelineEvent(
      time: '14:20',
      title: 'Запланирована дозаправка',
      description: 'АЗС «QazaqOil» · Блок B',
      status: _DriverTimelineStatus.current,
    ),
    _DriverTimelineEvent(
      time: '18:30',
      title: 'Разгрузка',
      description: 'Терминал «Capital Logistics» · Астана',
      status: _DriverTimelineStatus.upcoming,
    ),
  ];

  static const List<_DriverNotification> _notifications = [
    _DriverNotification(
      title: 'Комментарий диспетчера',
      description: 'За 40 минут до разгрузки подтвердите время прибытия.',
      time: '10:24',
      accentColor: Color(0xFF0E4ECF),
    ),
    _DriverNotification(
      title: 'Напоминание о техосмотре',
      description: 'Плановое ТО через 3 дня. Проверьте наличие документов.',
      time: '08:10',
      accentColor: Color(0xFF00B8A9),
    ),
    _DriverNotification(
      title: 'Обратная связь клиента',
      description: 'Отмечена своевременная доставка по рейсу №124.',
      time: 'Вчера',
      accentColor: Color(0xFFFFA000),
    ),
  ];

  static const _DriverRoutePlan _routePlan = _DriverRoutePlan(
    title: 'Алматы → Астана',
    status: 'В пути',
    departureTitle: 'Погрузка · 09:15',
    departureSubtitle: 'Склад «Fura24», пр. Абая 125',
    arrivalTitle: 'Разгрузка · 18:30',
    arrivalSubtitle: 'Терминал «Capital Logistics» · Астана',
    eta: 'ETA 18:30',
    distance: '1230 км',
    cargoHint: 'Температурный режим · 4 °C',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  Future<void> _handleRefresh() {
    return ref.read(profileProvider.notifier).loadProfile();
  }

  Future<void> _handleHeaderAction(_HeaderAction action) async {
    switch (action) {
      case _HeaderAction.profile:
        if (mounted) {
          context.push(DriverRoutes.profile);
        }
        break;
      case _HeaderAction.logout:
        await ref.read(authControllerProvider.notifier).logout();
        if (mounted) {
          context.go(AuthRoutes.welcomeScreen);
        }
        break;
    }
  }

  String _buildGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Доброе утро';
    } else if (hour >= 12 && hour < 18) {
      return 'Добрый день';
    } else if (hour >= 18 && hour < 22) {
      return 'Добрый вечер';
    }
    return 'Доброй ночи';
  }

  String _initialsFor(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return 'Д';
    }
    final parts =
        cleaned.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Д';
    }
    final buffer = StringBuffer();
    for (var i = 0; i < parts.length && i < 2; i++) {
      buffer.write(parts[i][0].toUpperCase());
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: _primaryColor,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            children: [
              _buildSummaryCard(profileState, user),
              SizedBox(height: 18.h),
              _buildRouteOverview(),
              SizedBox(height: 18.h),
              _buildMetricsCard(),
              SizedBox(height: 18.h),
              _buildTasksCard(),
              SizedBox(height: 18.h),
              _buildQuickActions(),
              SizedBox(height: 18.h),
              _buildNotifications(),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ProfileState state, UserModel? user) {
    final greeting = _buildGreeting();
    final nameFromProfile = (user?.username ?? '').trim();
    final displayName = nameFromProfile.isEmpty ? 'Водитель' : nameFromProfile;
    final subtitle =
        state.isLoading && user == null
            ? 'Загружаем ваш профиль и текущий рейс...'
            : 'Ваш план на сегодня готов. Работаем по шагам.';
    final initials = _initialsFor(displayName);
    final upcomingEvent = _timeline.firstWhere(
      (event) => event.status != _DriverTimelineStatus.completed,
      orElse: () => _timeline.last,
    );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: PopupMenuButton<_HeaderAction>(
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.black87,
                    size: 22.w,
                  ),
                  position: PopupMenuPosition.under,
                  onSelected: _handleHeaderAction,
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(
                          value: _HeaderAction.profile,
                          child: Text('Перейти в профиль'),
                        ),
                        PopupMenuItem(
                          value: _HeaderAction.logout,
                          child: Text('Выйти из аккаунта'),
                        ),
                      ],
                ),
              ),
              SizedBox(width: 12.w),
              CircleAvatar(
                radius: 26.w,
                backgroundColor: _primaryColor.withValues(alpha: 0.08),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              subtitle,
              key: ValueKey<String>(subtitle),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _buildInfoChip(
                icon: Icons.shield_outlined,
                label: 'Рейс подтверждён',
              ),
              _buildInfoChip(icon: Icons.access_time, label: 'График по плану'),
            ],
          ),
          SizedBox(height: 18.h),
          Divider(height: 1, color: _cardBorderColor),
          SizedBox(height: 18.h),
          _SummaryRow(
            icon: Icons.route_outlined,
            title: 'Маршрут',
            value: _routePlan.title,
            accent: _primaryColor,
          ),
          SizedBox(height: 12.h),
          _SummaryRow(
            icon: Icons.flag_circle_outlined,
            title: 'Ближайший шаг',
            value: '${upcomingEvent.title} · ${upcomingEvent.time}',
            subtitle: upcomingEvent.description,
            accent: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteOverview() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'Маршрут на сегодня',
            description: 'Главные точки рейса собраны на одной карточке.',
            trailing: _buildStatusPill(_routePlan.status),
          ),
          SizedBox(height: 18.h),
          _DriverRouteStep(
            title: _routePlan.departureTitle,
            subtitle: _routePlan.departureSubtitle,
            icon: Icons.upload_rounded,
            accent: _primaryColor,
          ),
          SizedBox(height: 16.h),
          _DriverRouteStep(
            title: _routePlan.arrivalTitle,
            subtitle: _routePlan.arrivalSubtitle,
            icon: Icons.download_rounded,
            accent: Colors.teal[600]!,
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                _buildRouteInfoChip(Icons.access_time, _routePlan.eta),
                _buildRouteInfoChip(Icons.route_outlined, _routePlan.distance),
                _buildRouteInfoChip(Icons.thermostat, _routePlan.cargoHint),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.open_in_new, size: 16.w),
              label: const Text('Детали рейса'),
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                textStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'Ключевые цифры',
            description: 'Понимание выполнения по рейсам и сервису.',
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, index) => _buildMetricTile(_stats[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'Ближайшие шаги',
            description: 'Отмечайте этапы по мере выполнения.',
          ),
          SizedBox(height: 16.h),
          for (var i = 0; i < _timeline.length; i++)
            _buildTaskRow(_timeline[i], isLast: i == _timeline.length - 1),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'Карточки действий',
            description: 'Частые задачи в одном клике.',
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quickActions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 2.6,
            ),
            itemBuilder:
                (context, index) => _buildActionCard(_quickActions[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'Напоминания',
            description: 'Свежие комментарии и задачи от команды.',
            trailing: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                padding: EdgeInsets.zero,
                textStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Все'),
            ),
          ),
          SizedBox(height: 16.h),
          for (var i = 0; i < _notifications.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == _notifications.length - 1 ? 0 : 12.h,
              ),
              child: _buildNotificationTile(_notifications[i]),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius.r),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeading({
    required String title,
    String? description,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        if (description != null) ...[
          SizedBox(height: 6.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _cardBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _primaryColor, size: 18.w),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _cardBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _primaryColor, size: 18.w),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(_DriverStat stat) {
    final Color highlight =
        stat.isPositive ? const Color(0xFF2BAF74) : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _cardBorderColor),
            ),
            child: Icon(stat.icon, color: _primaryColor, size: 20.w),
          ),
          SizedBox(height: 12.h),
          Text(
            stat.title,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 6.h),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(
                stat.isPositive ? Icons.trending_up : Icons.trending_down,
                color: highlight,
                size: 16.w,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  stat.trendLabel,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: highlight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(_DriverTimelineEvent event, {required bool isLast}) {
    late final Color accent;
    late final IconData icon;
    late final Color background;
    late final Color border;

    switch (event.status) {
      case _DriverTimelineStatus.completed:
        accent = const Color(0xFF2BAF74);
        icon = Icons.check_rounded;
        background = accent.withValues(alpha: 0.09);
        border = accent.withValues(alpha: 0.18);
        break;
      case _DriverTimelineStatus.current:
        accent = const Color(0xFFFFA000);
        icon = Icons.radio_button_checked;
        background = accent.withValues(alpha: 0.12);
        border = accent.withValues(alpha: 0.18);
        break;
      case _DriverTimelineStatus.upcoming:
        accent = const Color(0xFF9099A6);
        icon = Icons.circle_outlined;
        background = Colors.white;
        border = _cardBorderColor;
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: accent, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.time,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      _buildStatusPill(event.status.label, accent),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                      height: 1.35,
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

  Widget _buildActionCard(_DriverQuickAction action) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: _cardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: _cardBorderColor),
              ),
              child: Icon(action.icon, color: _primaryColor, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                action.label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(_DriverNotification notification) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: notification.accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: notification.accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: notification.accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.notifications_none,
              color: notification.accentColor,
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  notification.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  notification.time,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: notification.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, [Color? color]) {
    final Color accent = color ?? _primaryColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

enum _HeaderAction { profile, logout }

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: accent, size: 20.w),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4.h),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverRouteStep extends StatelessWidget {
  const _DriverRouteStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(icon, color: accent, size: 22.w),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverStat {
  const _DriverStat({
    required this.title,
    required this.value,
    required this.trendLabel,
    required this.isPositive,
    required this.icon,
  });

  final String title;
  final String value;
  final String trendLabel;
  final bool isPositive;
  final IconData icon;
}

class _DriverQuickAction {
  const _DriverQuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _DriverTimelineEvent {
  const _DriverTimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    required this.status,
  });

  final String time;
  final String title;
  final String description;
  final _DriverTimelineStatus status;
}

enum _DriverTimelineStatus { completed, current, upcoming }

extension on _DriverTimelineStatus {
  String get label {
    switch (this) {
      case _DriverTimelineStatus.completed:
        return 'Выполнено';
      case _DriverTimelineStatus.current:
        return 'Сейчас';
      case _DriverTimelineStatus.upcoming:
        return 'Ожидается';
    }
  }
}

class _DriverNotification {
  const _DriverNotification({
    required this.title,
    required this.description,
    required this.time,
    required this.accentColor,
  });

  final String title;
  final String description;
  final String time;
  final Color accentColor;
}

class _DriverRoutePlan {
  const _DriverRoutePlan({
    required this.title,
    required this.status,
    required this.departureTitle,
    required this.departureSubtitle,
    required this.arrivalTitle,
    required this.arrivalSubtitle,
    required this.eta,
    required this.distance,
    required this.cargoHint,
  });

  final String title;
  final String status;
  final String departureTitle;
  final String departureSubtitle;
  final String arrivalTitle;
  final String arrivalSubtitle;
  final String eta;
  final String distance;
  final String cargoHint;
}
