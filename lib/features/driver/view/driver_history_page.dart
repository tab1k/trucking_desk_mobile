import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/driver/providers/driver_assigned_orders_provider.dart';

class DriverHistoryPage extends ConsumerStatefulWidget {
  const DriverHistoryPage({super.key, this.onBackAction});

  final VoidCallback? onBackAction;

  @override
  ConsumerState<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends ConsumerState<DriverHistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  HistoryStatus _selectedStatus = HistoryStatus.all;
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final _ = ref.refresh(driverAssignedOrdersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(driverAssignedOrdersProvider);
    final items = ordersAsync.value ?? const <OrderSummary>[];
    final filteredItems = _applyFilters(items);

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
            if (_selectedRange != null ||
                _selectedStatus != HistoryStatus.all ||
                _searchController.text.trim().isNotEmpty)
              TextButton(
                onPressed: _resetFilters,
                child: Text(tr('history.reset')),
              ),
            SizedBox(width: 4.w),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            children: [
              _buildSearchField(theme),
              SizedBox(height: 12.h),
              _buildStatusChips(theme),
              SizedBox(height: 12.h),
              _buildDateRangeButton(theme),
              SizedBox(height: 20.h),
              if (ordersAsync.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (filteredItems.isEmpty)
                _buildEmptyState(theme)
              else
                ...filteredItems.map(
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
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
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

  Widget _buildStatusChips(ThemeData theme) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: HistoryStatus.values.map((status) {
        final isSelected = status == _selectedStatus;
        return ChoiceChip(
          label: Text(_statusLabel(status)),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedStatus = status;
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

  Widget _buildDateRangeButton(ThemeData theme) {
    final label = _selectedRange == null
        ? tr('history.date_range.select')
        : tr(
            'history.date_range.range',
            args: [
              _formatDate(_selectedRange!.start),
              _formatDate(_selectedRange!.end),
            ],
          );
    return OutlinedButton.icon(
      onPressed: _pickDateRange,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        foregroundColor: Colors.black87,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(top: 32.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 42.w, color: Colors.grey[500]),
            SizedBox(height: 10.h),
            Text(
              tr('history.empty.title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              tr('history.empty.subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black.withValues(alpha: 0.55),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDateRange: _selectedRange,
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  List<OrderSummary> _applyFilters(List<OrderSummary> orders) {
    final query = _searchController.text.trim().toLowerCase();
    return orders.where((order) {
      final matchesStatus =
          _selectedStatus == HistoryStatus.all ||
          (_selectedStatus == HistoryStatus.completed &&
              order.status == CargoStatus.completed) ||
          (_selectedStatus == HistoryStatus.cancelled &&
              order.status == CargoStatus.cancelled);

      final matchesDate =
          _selectedRange == null || _orderMatchesRange(order, _selectedRange!);

      final matchesQuery =
          query.isEmpty ||
          order.id.toLowerCase().contains(query) ||
          order.routeLabel.toLowerCase().contains(query);

      return matchesStatus && matchesDate && matchesQuery;
    }).toList();
  }

  bool _orderMatchesRange(OrderSummary order, DateTimeRange range) {
    final baseDate = order.transportationDate ?? order.createdAt;
    if (baseDate == null) return false;
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    return !baseDate.isBefore(start) && !baseDate.isAfter(end);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = HistoryStatus.all;
      _selectedRange = null;
    });
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
    return DateFormat('dd MMM yyyy', context.locale.toString()).format(date);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

enum HistoryStatus { all, completed, cancelled }

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.summary});

  final OrderSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  summary.routeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: summary.status == CargoStatus.completed
                      ? const Color(0xFFE6F6EC)
                      : const Color(0xFFFFE8E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  summary.status == CargoStatus.completed
                      ? tr('history.status.completed')
                      : tr('history.status.cancelled'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: summary.status == CargoStatus.completed
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFD32F2F),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey,
              ),
              SizedBox(width: 6.w),
              Text(
                tr(
                  'history.created_at',
                  args: [
                    (summary.transportationDate ?? summary.createdAt) != null
                        ? DateFormat('dd.MM.yyyy').format(
                            summary.transportationDate ?? summary.createdAt!,
                          )
                        : '—',
                  ],
                ),
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          if (summary.priceLabel.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                SizedBox(width: 6.w),
                Text(
                  summary.priceLabel,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          if (summary.description.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              summary.description,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade800,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
