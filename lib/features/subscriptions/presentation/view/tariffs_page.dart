import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:fura24.kz/features/subscriptions/data/repositories/subscriptions_repository.dart';
import 'package:fura24.kz/features/subscriptions/data/models/tariff_model.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';

final tariffsFutureProvider = FutureProvider.autoDispose<List<TariffModel>>((
  ref,
) {
  final repo = ref.watch(subscriptionsRepositoryProvider);
  return repo.fetchTariffs();
});

class TariffsPage extends ConsumerWidget {
  const TariffsPage({super.key});

  Color _getColor(String code) {
    if (code == 'INTERNATIONAL') return Colors.purple;
    if (code == 'INTERCITY') return Colors.orange;
    if (code == 'CITY') return Colors.blue;
    return Colors.black;
  }

  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    TariffModel tariff,
  ) async {
    final color = _getColor(tariff.code);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: color,
                      size: 32.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      'Подключение тарифа',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Вы собираетесь подключить тариф '),
                      TextSpan(
                        text: tariff.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const TextSpan(text: ' за '),
                      TextSpan(
                        text:
                            '${NumberFormat('#,##0', 'ru_RU').format(tariff.price)} ₸',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.pop(false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        backgroundColor: Colors.grey[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        tr('common.cancel'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        tr('common.confirm'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;

      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        final repo = ref.read(subscriptionsRepositoryProvider);
        await repo.purchaseTariff(tariff.code);

        // Hide loading
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Refresh Data
        ref.refresh(tariffsFutureProvider);
        ref.read(profileProvider.notifier).loadProfile(); // Refresh balance

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Тариф успешно подключен!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Hide loading if visible (we know it is because of the flow, but good to check)
        if (context.mounted) {
          // We need to pop the loading dialog.
          // We can use a flag or just pop via root navigator and hope.
          // Better: just pop once.
          Navigator.of(context, rootNavigator: true).pop();
        }

        String errorMsg = 'Ошибка при подключении';
        if (e is DioException) {
          errorMsg = e.response?.data?['error'] ?? errorMsg;
        } else {
          errorMsg = e.toString();
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tariffsAsync = ref.watch(tariffsFutureProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 60.h,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Material(
            color: Colors.grey[200],
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              color: Colors.black87,
              padding: EdgeInsets.zero,
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Text(
            'Тарифы',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: tariffsAsync.when(
        data: (tariffs) {
          if (tariffs.isEmpty) {
            return const Center(child: Text('Нет доступных тарифов'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: tariffs.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              return _TariffCard(
                tariff: tariffs[index],
                onPurchase: (t) => _handlePurchase(context, ref, t),
              );
            },
          );
        },
        error: (err, stack) => Center(
          child: Text('Ошибка загрузки: $err', textAlign: TextAlign.center),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TariffCard extends StatelessWidget {
  const _TariffCard({required this.tariff, required this.onPurchase});

  final TariffModel tariff;
  final Function(TariffModel) onPurchase;

  @override
  Widget build(BuildContext context) {
    final color = _getColor(tariff.code);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: tariff.isActive ? color : Colors.grey[200]!,
          width: tariff.isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tariff.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (tariff.isActive)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Активен',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${NumberFormat('#,##0', 'ru_RU').format(tariff.price)} ₸ / месяц',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  tariff.description,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 16.h),
                ...tariff.features.map((feature) => _FeatureRow(text: feature)),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: tariff.isActive
                        ? null
                        : () => onPurchase(tariff),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tariff.isActive
                          ? Colors.grey[300]
                          : color,
                      foregroundColor: tariff.isActive
                          ? Colors.black54
                          : Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.black38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      tariff.isActive ? 'Уже подключен' : 'Подключить',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String code) {
    if (code == 'INTERNATIONAL') return Colors.purple;
    if (code == 'INTERCITY') return Colors.orange;
    if (code == 'CITY') return Colors.blue;
    return Colors.black;
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
