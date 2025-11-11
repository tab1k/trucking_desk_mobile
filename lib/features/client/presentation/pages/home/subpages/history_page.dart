import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  HistoryStatus _selectedStatus = HistoryStatus.all;
  DateTimeRange? _selectedRange;
  late final List<_HistoryItem> _allItems;
  late List<_HistoryItem> _visibleItems;

  @override
  void initState() {
    super.initState();
    _allItems = _mockHistoryItems;
    _visibleItems = List.of(_allItems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: Colors.black87,
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(left: 10.w),
            child: Text(
              'История заказов',
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
                child: const Text('Сбросить'),
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
              if (_visibleItems.isEmpty)
                _buildEmptyState(theme)
              else
                ..._visibleItems.map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _HistoryCard(item: item),
                    )),
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
      onChanged: (_) => _applyFilters(),
      decoration: InputDecoration(
        hintText: 'Поиск по номеру, маршруту или компании',
        prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[500]),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.grey[500],
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
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
      style: TextStyle(
        fontSize: 14.sp,
        color: Colors.black87,
      ),
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
            _applyFilters();
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
        ? 'Выбрать период'
        : '${_formatDate(_selectedRange!.start)} — ${_formatDate(_selectedRange!.end)}';

    return OutlinedButton.icon(
      onPressed: _pickDateRange,
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(
        label,
        style: TextStyle(fontSize: 14.sp),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
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
            'Здесь будет история ваших заказов',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Попробуйте изменить фильтры или создать новый заказ, чтобы он появился в списке.',
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00B2FF)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _visibleItems = _allItems.where((item) {
        final matchesStatus = _selectedStatus == HistoryStatus.all ||
            item.status == _selectedStatus;

        final matchesDate = _selectedRange == null ||
            (item.date.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) &&
                item.date.isBefore(_selectedRange!.end.add(const Duration(days: 1))));

        final matchesQuery = query.isEmpty ||
            item.id.toLowerCase().contains(query) ||
            item.route.toLowerCase().contains(query) ||
            item.company.toLowerCase().contains(query);

        return matchesStatus && matchesDate && matchesQuery;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = HistoryStatus.all;
      _selectedRange = null;
      _visibleItems = List.of(_allItems);
    });
  }

  String _statusLabel(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.all:
        return 'Все';
      case HistoryStatus.completed:
        return 'Завершено';
      case HistoryStatus.cancelled:
        return 'Отменено';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

enum HistoryStatus { all, completed, cancelled }

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final _HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                item.id,
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
                  color: _statusBackground(item.status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusTitle(item.status),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(item.status),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            item.route,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Отправка: ${_formatDate(item.date)}',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.company,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.cargo,
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
                    item.price,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Оплата: ${item.payment}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.notes.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                item.notes,
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
                'Создано: ${_formatDateTime(item.createdAt)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: const Text('Подробнее'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(HistoryStatus status) {
    if (status == HistoryStatus.completed) {
      return const Color(0xFF2EB872);
    }
    if (status == HistoryStatus.cancelled) {
      return const Color(0xFFEA5B5B);
    }
    return const Color(0xFF6B6B6B);
  }

  Color _statusBackground(HistoryStatus status) {
    return _statusColor(status).withValues(alpha: 0.12);
  }

  String _formatDate(DateTime date) {
    final months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${_formatDate(date)} · $time';
  }

  String _statusTitle(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.completed:
        return 'Завершено';
      case HistoryStatus.cancelled:
        return 'Отменено';
      case HistoryStatus.all:
        return 'Все';
    }
  }
}

class _HistoryItem {
  const _HistoryItem({
    required this.id,
    required this.date,
    required this.route,
    required this.company,
    required this.cargo,
    required this.price,
    required this.payment,
    required this.status,
    required this.createdAt,
    this.notes = '',
  });

  final String id;
  final DateTime date;
  final String route;
  final String company;
  final String cargo;
  final String price;
  final String payment;
  final HistoryStatus status;
  final DateTime createdAt;
  final String notes;
}

final List<_HistoryItem> _mockHistoryItems = [
  _HistoryItem(
    id: 'ORD-1482',
    date: DateTime.now().subtract(const Duration(days: 2)),
    route: 'Алматы → Астана',
    company: 'ТОО «KazTrans»',
    cargo: 'Фрукты · 18 т · Рефрижератор',
    price: '480 000 ₸',
    payment: 'Безнал',
    status: HistoryStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(days: 8, hours: 4)),
    notes: 'Доставка прошла без задержек. Водитель связался за сутки до прибытия.',
  ),
  _HistoryItem(
    id: 'ORD-1520',
    date: DateTime.now().subtract(const Duration(days: 1)),
    route: 'Шымкент → Караганда',
    company: 'Asia Freight',
    cargo: 'Стройматериалы · 20 т · Тент',
    price: '360 000 ₸',
    payment: 'Наличными',
    status: HistoryStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 6)),
    notes: 'Ожидается прибытие на выгрузку завтра вечером.',
  ),
  _HistoryItem(
    id: 'ORD-1395',
    date: DateTime.now().subtract(const Duration(days: 5)),
    route: 'Астана → Костанай',
    company: 'North Cargo',
    cargo: 'Металлоконструкции · 15 т · Платформа',
    price: '410 000 ₸',
    payment: 'Безнал',
    status: HistoryStatus.cancelled,
    createdAt: DateTime.now().subtract(const Duration(days: 6, hours: 2)),
    notes: 'Заказ отменён из-за переносов сроков погрузки. Средства возвращены.',
  ),
  _HistoryItem(
    id: 'ORD-1440',
    date: DateTime.now().subtract(const Duration(days: 9)),
    route: 'Усть-Каменогорск → Алматы',
    company: 'Logex KZ',
    cargo: 'Оборудование · 8 т · Фургон',
    price: '295 000 ₸',
    payment: 'Предоплата',
    status: HistoryStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
  ),
];
