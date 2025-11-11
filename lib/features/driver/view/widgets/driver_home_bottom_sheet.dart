import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum DriverQuickAction {
  startTrip,
  confirmLoading,
  addExpense,
  contactDispatcher,
}

const _driverActionColor = Color(0xFF00B2FF);

class DriverHomeBottomSheet extends StatelessWidget {
  const DriverHomeBottomSheet({
    super.key,
    required this.scrollController,
    this.onQuickActionSelected,
  });

  final ScrollController scrollController;
  final ValueChanged<DriverQuickAction>? onQuickActionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.r),
          topRight: Radius.circular(18.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.r),
          topRight: Radius.circular(18.r),
        ),
        child: Stack(
          children: [
            _DriverSheetContent(
              scrollController: scrollController,
              onQuickActionSelected: onQuickActionSelected,
            ),
            const _SheetHandle(),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 64,
          height: 20,
          alignment: Alignment.topCenter,
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverSheetContent extends StatelessWidget {
  const _DriverSheetContent({
    required this.scrollController,
    required this.onQuickActionSelected,
  });

  final ScrollController scrollController;
  final ValueChanged<DriverQuickAction>? onQuickActionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Рабочие действия',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'Следите за рейсом и отмечайте ключевые события.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/truck-check.svg',
                  width: 24.w,
                  height: 24.h,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _DriverActionCard(
                    iconAsset: 'assets/svg/truck-moving.svg',
                    title: 'Начать рейс',
                    color: _driverActionColor,
                    onTap: () =>
                        onQuickActionSelected?.call(DriverQuickAction.startTrip),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _DriverActionCard(
                    iconAsset: 'assets/svg/truck-loading.svg',
                    title: 'Статус загрузки',
                    color: _driverActionColor,
                    onTap: () => onQuickActionSelected
                        ?.call(DriverQuickAction.confirmLoading),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _DriverActionCard(
                    iconAsset: 'assets/svg/calculator.svg',
                    title: 'Расходы',
                    color: _driverActionColor,
                    onTap: () => onQuickActionSelected
                        ?.call(DriverQuickAction.addExpense),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _DriverActionCard(
                    iconAsset: 'assets/svg/phone-call.svg',
                    title: 'Диспетчер',
                    color: _driverActionColor,
                    onTap: () => onQuickActionSelected
                        ?.call(DriverQuickAction.contactDispatcher),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _DriverActionListTile(
              iconAsset: 'assets/svg/plus.svg',
              title: 'Создать заказ',
              onTap: () {
                // TODO: hook up to order creation flow
              },
            ),

            SizedBox(height: 8.h),
            _DriverActionListTile(
              iconAsset: 'assets/svg/search.svg',
              title: 'Найти транспорт',
              onTap: () {
                // TODO: hook up to order creation flow
              },
            ),
            
            SizedBox(height: 8.h),
            _DriverActionListTile(
              iconAsset: 'assets/svg/box.svg',
              title: 'Мои грузы',
              onTap: () {
                // TODO: hook up to order creation flow
              },
            ),
          ],
        ),
        SizedBox(height: 18.h),
        const _DriverStoriesStrip(),
        SizedBox(height: 12.h),
        const _DriverInsightsCard(),
      ],
    );
  }
}

class _DriverActionCard extends StatelessWidget {
  const _DriverActionCard({
    required this.iconAsset,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          height: 100.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withOpacity(0.20),
              width: 0.6,
            ),
          ),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconAsset,
                      width: 20.r,
                      height: 20.r,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverStoryItem {
  const _DriverStoryItem({
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.isNew = false,
  });

  final String title;
  final String imageUrl;
  final String? subtitle;
  final bool isNew;
}

const List<_DriverStoryItem> _driverStories = [
  _DriverStoryItem(
    title: 'Маршруты без задержек',
    subtitle: 'Как обходить загруженные участки',
    imageUrl:
        'https://images.unsplash.com/photo-1477414348463-c0eb7f1359b6?auto=format&fit=crop&w=900&q=80',
    isNew: true,
  ),
  _DriverStoryItem(
    title: 'Чек-лист перед рейсом',
    subtitle: '5 минут — и вы готовы в путь',
    imageUrl:
        'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
  ),
  _DriverStoryItem(
    title: 'Советы по экономии топлива',
    subtitle: 'Что учитывать на трассе',
    imageUrl:
        'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&w=900&q=80',
  ),
  _DriverStoryItem(
    title: 'Работа с клиентом',
    subtitle: 'Как держать связь по рейсу',
    imageUrl:
        'https://images.unsplash.com/photo-1459478309853-2c33a60058e7?auto=format&fit=crop&w=900&q=80',
  ),
  _DriverStoryItem(
    title: 'Документы без ошибок',
    subtitle: 'Частые вопросы при загрузке',
    imageUrl:
        'https://images.unsplash.com/photo-1473968512647-3e447244af8f?auto=format&fit=crop&w=900&q=80',
    isNew: true,
  ),
];

class _DriverStoriesStrip extends StatelessWidget {
  const _DriverStoriesStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final story = _driverStories[index];
          return _DriverStoryCard(item: story);
        },
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemCount: _driverStories.length,
      ),
    );
  }
}

class _DriverStoryCard extends StatelessWidget {
  const _DriverStoryCard({required this.item});

  final _DriverStoryItem item;

  void _openStory(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.black.withOpacity(0.2),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color.fromARGB(200, 0, 0, 0),
                          Color.fromARGB(80, 0, 0, 0),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.subtitle != null)
                          Text(
                            item.subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        SizedBox(height: 8.h),
                        Text(
                          item.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _openStory(context),
      child: SizedBox(
        width: 95.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.25),
                  width: 1.4,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: SizedBox(
                  height: 92.h,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey.shade600,
                              size: 28.w,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (item.isNew)
                        Positioned(
                          top: 10.h,
                          left: 10.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      theme.colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'NEW',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 8.w,
                        right: 12.w,
                        bottom: 12.h,
                        child: Text(
                          item.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              item.subtitle ?? item.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(
                  item.subtitle != null ? 0.65 : 0.85,
                ),
                fontSize: 12.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverInsightsCard extends StatelessWidget {
  const _DriverInsightsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0E4ECF).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xFF0E4ECF).withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Контроль рейса',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Отправьте отчёт о текущем статусе и получите рекомендации по следующей точке маршрута.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.route_outlined,
              color: const Color(0xFF0E4ECF),
              size: 24.r,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverActionListTile extends StatelessWidget {
  const _DriverActionListTile({
    required this.iconAsset,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String iconAsset;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _driverActionColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _driverActionColor.withOpacity(0.20),
              width: 0.6,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.all(6.r),
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: _driverActionColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                  child: SvgPicture.asset(
                    iconAsset,
                    width: 18.w,
                    height: 18.h,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: 14.sp,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 8.w),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
