import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fura24.kz/features/client/domain/models/history_filter.dart';
import 'package:fura24.kz/features/client/domain/models/history_status.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/client/presentation/providers/history_orders_provider.dart';
import 'package:fura24.kz/shared/widgets/app_date_picker.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key, this.onBackAction});

  final VoidCallback? onBackAction;

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = ref.read(historyFilterProvider);
    _searchController.text = filter.searchQuery;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(historyFilterProvider);
    final ordersAsync = ref.watch(historyOrdersProvider);
    final items = ordersAsync.value ?? const <OrderSummary>[];

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
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
                onPressed:
                    widget.onBackAction ?? () => Navigator.of(context).pop(),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(left: 10.w),
            child: Text(
              tr('history.title'),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          actions: [
            if (filter.dateRange != null ||
                filter.status != HistoryStatus.all ||
                filter.searchQuery.isNotEmpty)
              TextButton(
                onPressed: _resetFilters,
                child: Text(tr('history.reset')),
              ),
            SizedBox(width: 4.w),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () async {
              // Invalidate ensures a fresh fetch with current filters
              ref.invalidate(historyOrdersProvider);
            },
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                _buildSearchField(theme),
                SizedBox(height: 12.h),
                _buildStatusChips(theme, filter),
                SizedBox(height: 12.h),
                _buildDateRangeButton(theme, filter),
                SizedBox(height: 20.h),
                if (ordersAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  _buildEmptyState(theme)
                else
                  ...items.map(
                    (order) => Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _HistoryCard(summary: order),
                    ),
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      onSubmitted: (value) {
        ref.read(historyFilterProvider.notifier).update((state) {
          return state.copyWith(searchQuery: value.trim());
        });
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: tr('history.search_hint'),
        prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[500]),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.grey[500],
                onPressed: () {
                  _searchController.clear();
                  ref.read(historyFilterProvider.notifier).update((state) {
                    return state.copyWith(searchQuery: '');
                  });
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFF00B2FF), width: 1.4),
        ),
      ),
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
    );
  }

  Widget _buildStatusChips(ThemeData theme, HistoryFilter filter) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: HistoryStatus.values.map((status) {
        final isSelected = status == filter.status;
        return ChoiceChip(
          label: Text(_statusLabel(status)),
          selected: isSelected,
          onSelected: (_) {
            ref.read(historyFilterProvider.notifier).update((state) {
              return state.copyWith(status: status);
            });
          },
          labelStyle: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black,
          ),
          selectedColor: const Color(0xFF00B2FF),
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF00B2FF)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeButton(ThemeData theme, HistoryFilter filter) {
    final label = filter.dateRange == null
        ? tr('history.date_range.select')
        : tr(
            'history.date_range.range',
            args: [
              _formatDate(filter.dateRange!.start),
              _formatDate(filter.dateRange!.end),
            ],
          );

    return OutlinedButton.icon(
      onPressed: () => _pickDateRange(filter.dateRange),
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(label, style: TextStyle(fontSize: 14.sp)),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        side: BorderSide(color: Colors.grey[200]!),
        foregroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48.w, color: Colors.grey[400]),
          SizedBox(height: 12.h),
          Text(
            tr('history.empty.title'),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            tr('history.empty.subtitle'),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(DateTimeRange? currentRange) async {
    final picked = await showAppDateRangePicker(
      context,
      initialRange: currentRange,
    );
    if (picked != null) {
      ref.read(historyFilterProvider.notifier).update((state) {
        return state.copyWith(dateRange: picked);
      });
    }
  }

  void _resetFilters() {
    _searchController.clear();
    ref.read(historyFilterProvider.notifier).update((state) {
      return const HistoryFilter();
    });
    setState(() {});
  }

  String _statusLabel(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.all:
        return tr('history.filters.all');
      case HistoryStatus.completed:
        return tr('history.filters.completed');
      case HistoryStatus.cancelled:
        return tr('history.filters.cancelled');
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.summary});

  final OrderSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transportDate = summary.transportationDate ?? summary.createdAt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '№${summary.id}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _statusBackground(summary.status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusTitle(summary.status),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(summary.status),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            summary.routeLabel,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            transportDate != null
                ? 'Отправка: ${_formatDate(transportDate)}'
                : 'Дата: ${summary.dateLabel}',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.senderName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      summary.cargoName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    summary.priceLabel,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    summary.paymentTypeLabel,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _Chip(label: summary.weightLabel),
              SizedBox(width: 8.w),
              _Chip(label: summary.volumeLabel),
              SizedBox(width: 8.w),
              _Chip(label: summary.vehicleTypeLabel),
            ],
          ),
          if (summary.description.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                summary.description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.schedule, size: 16.w, color: Colors.grey[500]),
              SizedBox(width: 6.w),
              Text(
                summary.createdAt != null
                    ? 'Создано: ${_formatDateTime(summary.createdAt!)}'
                    : 'Создано: ${summary.dateLabel}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(CargoStatus status) {
    switch (status) {
      case CargoStatus.completed:
        return const Color(0xFF2EB872);
      case CargoStatus.cancelled:
        return const Color(0xFFEA5B5B);
      case CargoStatus.inTransit:
        return const Color(0xFFFF9800);
      case CargoStatus.pending:
        return const Color(0xFF6B6B6B);
    }
  }

  Color _statusBackground(CargoStatus status) {
    return _statusColor(status).withValues(alpha: 0.12);
  }

  String _statusTitle(CargoStatus status) {
    switch (status) {
      case CargoStatus.completed:
        return 'Завершено';
      case CargoStatus.cancelled:
        return 'Отменено';
      case CargoStatus.inTransit:
        return 'В пути';
      case CargoStatus.pending:
        return 'Ожидает';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${_formatDate(date)} · $time';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}
