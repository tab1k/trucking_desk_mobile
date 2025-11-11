import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/models/home_quick_action.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/action_card.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/calculate_card.dart';

class HomeBottomSheet extends StatelessWidget {
  const HomeBottomSheet({
    super.key,
    required this.scrollController,
    required this.onQuickActionSelected,
  });

  final ScrollController scrollController;
  final ValueChanged<HomeQuickAction> onQuickActionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        child: Stack(
          children: [
            _HomeSheetContent(
              scrollController: scrollController,
              onQuickActionSelected: onQuickActionSelected,
            ),
            Positioned(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSheetContent extends StatelessWidget {
  const _HomeSheetContent({
    required this.scrollController,
    required this.onQuickActionSelected,
  });

  final ScrollController scrollController;
  final ValueChanged<HomeQuickAction> onQuickActionSelected;

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
                    'Ваши действия',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'Выберите подходящую опцию, чтобы продолжить работу.',
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
                  'assets/svg/ticket.svg',
                  width: 22.w,
                  height: 22.h,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary,
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
                  child: HomeActionCard(
                    iconAsset: 'assets/svg/plus.svg',
                    title: 'Создать заказ',
                    onTap: () =>
                        onQuickActionSelected(HomeQuickAction.createOrder),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: HomeActionCard(
                    iconAsset: 'assets/svg/search.svg',
                    title: 'Найти транспорт',
                    onTap: () =>
                        onQuickActionSelected(HomeQuickAction.findRide),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: HomeActionCard(
                    iconAsset: 'assets/svg/box.svg',
                    title: 'Мои грузы',
                    onTap: () =>
                        onQuickActionSelected(HomeQuickAction.myCargo),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: HomeActionCard(
                    iconAsset: 'assets/svg/history.svg',
                    title: 'История',
                    onTap: () =>
                        onQuickActionSelected(HomeQuickAction.history),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 18.h),
        const HomeStoriesStrip(),
        SizedBox(height: 12.h),
        const HomeCalculateCard(),
      ],
    );
  }
}

class HomeStoryItem {
  const HomeStoryItem({
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

const List<HomeStoryItem> homeStories = [
  HomeStoryItem(
    title: 'Лайфхаки по заказам',
    subtitle: 'Как быстро оформить груз',
    imageUrl:
        'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=900&q=80',
    isNew: true,
  ),
  HomeStoryItem(
    title: 'Новые направления',
    subtitle: 'Астана ↔︎ Алматы',
    imageUrl:
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=900&q=80',
  ),
  HomeStoryItem(
    title: 'Советы водителей',
    subtitle: 'Что учесть при загрузке',
    imageUrl:
        'https://images.unsplash.com/photo-1541417904950-b855846fe074?auto=format&fit=crop&w=900&q=80',
  ),
  HomeStoryItem(
    title: 'Команда Fura24',
    subtitle: 'Познакомьтесь ближе',
    imageUrl:
        'https://images.unsplash.com/photo-1545239351-1141bd82e8a6?auto=format&fit=crop&w=900&q=80',
  ),
  HomeStoryItem(
    title: 'Акции и бонусы',
    subtitle: 'Скидки для постоянных',
    imageUrl:
        'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?auto=format&fit=crop&w=900&q=80',
    isNew: true,
  ),
];

class HomeStoriesStrip extends StatelessWidget {
  const HomeStoriesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final story = homeStories[index];
          return HomeStoryCard(item: story);
        },
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemCount: homeStories.length,
      ),
    );
  }
}

class HomeStoryCard extends StatelessWidget {
  const HomeStoryCard({super.key, required this.item});

  final HomeStoryItem item;

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
                                  color: theme.colorScheme.primary.withOpacity(0.4),
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
