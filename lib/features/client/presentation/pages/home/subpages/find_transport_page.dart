import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FindTransportPage extends StatefulWidget {
  const FindTransportPage({super.key});

  @override
  State<FindTransportPage> createState() => _FindTransportPageState();
}

class _FindTransportPageState extends State<FindTransportPage> {
  final _loadingPointController = TextEditingController();
  final _unloadingPointController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _loadingTypeController = TextEditingController();

  bool _showAdvancedFilters = false;
  final _weightFromController = TextEditingController();
  final _weightToController = TextEditingController();
  final _volumeFromController = TextEditingController();
  final _volumeToController = TextEditingController();
  final _dateController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime? _selectedDate;

  late final List<_TransportOffer> _allOffers;
  late List<_TransportOffer> _visibleOffers;

  @override
  void initState() {
    super.initState();
    _allOffers = _mockOffers;
    _visibleOffers = List.of(_allOffers);
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
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              'Поиск транспорта',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          )
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            children: [
              SizedBox(height: 16.h),
              _buildFilterCard(theme),
              SizedBox(height: 24.h),
              Text(
                'Доступные варианты',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              if (_visibleOffers.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 36.w,
                        width: 36.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'По выбранным параметрам пока нет подходящих машин. Попробуйте изменить фильтры.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._visibleOffers.map((offer) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _TransportOfferCard(offer: offer),
                  );
                }),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Фильтры',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                icon: Icon(
                  _showAdvancedFilters
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                ),
                label: Text(
                  _showAdvancedFilters ? 'Скрыть' : 'Расширенные фильтры',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          _buildInputField(
            controller: _loadingPointController,
            label: 'Пункт загрузки',
            icon: Icons.location_on_outlined,
          ),
          SizedBox(height: 12.h),
          _buildInputField(
            controller: _unloadingPointController,
            label: 'Пункт разгрузки',
            icon: Icons.flag_outlined,
          ),
          if (_showAdvancedFilters) ...[
            SizedBox(height: 12.h),
            _buildInputField(
              controller: _vehicleTypeController,
              label: 'Тип машины',
              icon: Icons.local_shipping_outlined,
            ),
            SizedBox(height: 12.h),
            _buildInputField(
              controller: _loadingTypeController,
              label: 'Погрузка',
              icon: Icons.precision_manufacturing_outlined,
            ),
            SizedBox(height: 16.h),
            _buildRangeRow(
              leftController: _weightFromController,
              rightController: _weightToController,
              leftLabel: 'Вес от (кг)',
              rightLabel: 'Вес до (кг)',
              icon: Icons.scale_outlined,
            ),
            SizedBox(height: 12.h),
            _buildRangeRow(
              leftController: _volumeFromController,
              rightController: _volumeToController,
              leftLabel: 'Объём от (м³)',
              rightLabel: 'Объём до (м³)',
              icon: Icons.aspect_ratio_outlined,
            ),
            SizedBox(height: 12.h),
            _buildDateField(),
            SizedBox(height: 12.h),
            _buildInputField(
              controller: _durationController,
              label: 'Срок перевозки',
              icon: Icons.access_time_outlined,
            ),
          ],
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.search, size: 18),
              label: Text(
                'Искать машину',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B2FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
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

  Widget _buildRangeRow({
    required TextEditingController leftController,
    required TextEditingController rightController,
    required String leftLabel,
    required String rightLabel,
    required IconData icon,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: leftController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: leftLabel,
              prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
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
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: TextField(
            controller: rightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: rightLabel,
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
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return TextField(
      controller: _dateController,
      readOnly: true,
      onTap: _pickDate,
      decoration: InputDecoration(
        hintText: 'Дата перевозки',
        prefixIcon: Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey[500]),
        suffixIcon: Icon(Icons.edit_calendar_outlined, size: 20, color: Colors.grey[500]),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00B2FF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
      });
    }
  }

  void _applyFilters() {
    final originQuery = _loadingPointController.text.trim().toLowerCase();
    final destinationQuery = _unloadingPointController.text.trim().toLowerCase();
    final vehicleQuery = _vehicleTypeController.text.trim().toLowerCase();
    final loadQuery = _loadingTypeController.text.trim().toLowerCase();
    final weightFrom = double.tryParse(_weightFromController.text.replaceAll(',', '.'));
    final weightTo = double.tryParse(_weightToController.text.replaceAll(',', '.'));
    final volumeFrom = double.tryParse(_volumeFromController.text.replaceAll(',', '.'));
    final volumeTo = double.tryParse(_volumeToController.text.replaceAll(',', '.'));
    final selectedDate = _selectedDate;

    setState(() {
      _visibleOffers = _allOffers.where((offer) {
        final matchesOrigin = originQuery.isEmpty ||
            offer.origin.toLowerCase().contains(originQuery);
        final matchesDestination = destinationQuery.isEmpty ||
            offer.destination.toLowerCase().contains(destinationQuery);
        final matchesVehicle = vehicleQuery.isEmpty ||
            offer.vehicle.toLowerCase().contains(vehicleQuery);
        final matchesLoad = loadQuery.isEmpty ||
            offer.loadType.toLowerCase().contains(loadQuery);

        final matchesWeight = (weightFrom == null || offer.capacity >= weightFrom) &&
            (weightTo == null || offer.capacity <= weightTo);
        final matchesVolume = (volumeFrom == null || offer.volume >= volumeFrom) &&
            (volumeTo == null || offer.volume <= volumeTo);

    final matchesDate = selectedDate == null ||
        (offer.date.year == selectedDate.year &&
            offer.date.month == selectedDate.month &&
            offer.date.day == selectedDate.day);

        return matchesOrigin &&
            matchesDestination &&
            matchesVehicle &&
            matchesLoad &&
            matchesWeight &&
            matchesVolume &&
            matchesDate;
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Фильтры применены'),
        backgroundColor: const Color(0xFF00B2FF),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: 16.h,
          left: 16.w,
          right: 16.w,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadingPointController.dispose();
    _unloadingPointController.dispose();
    _vehicleTypeController.dispose();
    _loadingTypeController.dispose();
    _weightFromController.dispose();
    _weightToController.dispose();
    _volumeFromController.dispose();
    _volumeToController.dispose();
    _dateController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}

class _TransportOfferCard extends StatelessWidget {
  const _TransportOfferCard({required this.offer});

  final _TransportOffer offer;

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
            color: Colors.black.withOpacity(0.03),
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  offer.id,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.star, color: Colors.amber, size: 16.w),
              SizedBox(width: 4.w),
              Text(
                offer.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 12.w),
              _FavoriteButton(onPressed: () {}),
            ],
          ),
          SizedBox(height: 12.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${offer.origin} → ${offer.destination}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Дата отправки: ${_formatDate(offer.date)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.vehicle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${offer.loadType} • ${offer.capacity.toStringAsFixed(1)} т • ${offer.volume.toStringAsFixed(1)} м³',
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
                    offer.price,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'за рейс',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              CircleAvatar(
                radius: 18.w,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  offer.company.isNotEmpty ? offer.company.characters.first : '',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  offer.company,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: const Text('Связаться'),
              ),
            ],
          ),
          if (offer.tags.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: offer.tags
                  .map(
                    (tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
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
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _isFavorite = false;

  void _handleTap() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color iconColor = _isFavorite ? theme.colorScheme.primary : Colors.grey[500]!;

    return SizedBox(
      width: 32.w,
      height: 32.w,
      child: IconButton(
        onPressed: _handleTap,
        constraints: BoxConstraints.tightFor(width: 32.w, height: 32.w),
        splashRadius: 20.w,
        padding: EdgeInsets.zero,
        icon: SvgPicture.asset(
          'assets/svg/heart.svg',
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _TransportOffer {
  const _TransportOffer({
    required this.id,
    required this.origin,
    required this.destination,
    required this.date,
    required this.vehicle,
    required this.loadType,
    required this.capacity,
    required this.volume,
    required this.price,
    required this.company,
    required this.rating,
    this.tags = const [],
  });

  final String id;
  final String origin;
  final String destination;
  final DateTime date;
  final String vehicle;
  final String loadType;
  final double capacity;
  final double volume;
  final String price;
  final String company;
  final double rating;
  final List<String> tags;
}

final List<_TransportOffer> _mockOffers = [
  _TransportOffer(
    id: 'TR-2915',
    origin: 'Алматы',
    destination: 'Астана',
    date: DateTime.now().add(const Duration(days: 3)),
    vehicle: 'Рефрижератор 20 т',
    loadType: 'Задняя погрузка',
    capacity: 20,
    volume: 82,
    price: '450 000 ₸',
    company: 'ТОО «Алтай Логистик»',
    rating: 4.8,
    tags: ['GPS-мониторинг', '24/7 связь'],
  ),
  _TransportOffer(
    id: 'TR-3058',
    origin: 'Караганда',
    destination: 'Павлодар',
    date: DateTime.now().add(const Duration(days: 1)),
    vehicle: 'Тент 15 т',
    loadType: 'Верхняя/боковая погрузка',
    capacity: 15,
    volume: 60,
    price: '320 000 ₸',
    company: 'Logex KZ',
    rating: 4.6,
    tags: ['Опыт 7 лет'],
  ),
  _TransportOffer(
    id: 'TR-1984',
    origin: 'Шымкент',
    destination: 'Алматы',
    date: DateTime.now().add(const Duration(days: 5)),
    vehicle: 'Фургон 10 т',
    loadType: 'Гидроборт',
    capacity: 10,
    volume: 45,
    price: '280 000 ₸',
    company: 'Asia Freight',
    rating: 4.9,
    tags: ['Страховка груза', 'Закрепление'],
  ),
  _TransportOffer(
    id: 'TR-4120',
    origin: 'Астана',
    destination: 'Костанай',
    date: DateTime.now().add(const Duration(days: 2)),
    vehicle: 'Открытая платформа 25 т',
    loadType: 'Погрузчик/кран',
    capacity: 25,
    volume: 90,
    price: '500 000 ₸',
    company: 'North Cargo',
    rating: 4.5,
    tags: ['Негабарит', 'Документы'],
  ),
];
