import 'package:easy_localization/easy_localization.dart';

class PartnerOption {
  const PartnerOption({required this.value, required this.label});
  final String value;
  final String label;
}

class PartnerOptions {
  static List<PartnerOption> get activities => [
    PartnerOption(value: 'CARRIER', label: 'Перевозчик'),
    PartnerOption(value: 'FORWARDER', label: 'Экспедитор'),
    PartnerOption(value: 'SHIPPER', label: 'Грузовладелец'),
    PartnerOption(value: 'LOGISTICS_PROVIDER', label: 'Логистический оператор'),
    PartnerOption(value: 'DISPATCH', label: 'Диспетчерская/агент'),
    PartnerOption(value: 'BROKER', label: 'Брокер/агент'),
    PartnerOption(value: 'WAREHOUSE', label: 'Склад/Терминал'),
    PartnerOption(value: 'FUEL_STATION', label: 'АЗС/топливные карты'),
    PartnerOption(value: 'SERVICE_STATION', label: 'СТО/ремонт'),
    PartnerOption(value: 'TIRE_SERVICE', label: 'Шиномонтаж'),
    PartnerOption(value: 'PARKING', label: 'Стоянки/парковки'),
    PartnerOption(value: 'WASH', label: 'Автомойка'),
    PartnerOption(value: 'INSURANCE', label: 'Страхование'),
    PartnerOption(value: 'LEASING', label: 'Лизинг/финансы'),
    PartnerOption(value: 'BANKING', label: 'Банки/эквайринг'),
    PartnerOption(value: 'CUSTOMS', label: 'Таможенные услуги'),
    PartnerOption(value: 'TELEMATICS', label: 'GPS/телематика'),
    PartnerOption(value: 'IT_SERVICES', label: 'IT/цифровые сервисы'),
    PartnerOption(value: 'ROAD_SERVICE', label: 'Дорожная помощь'),
    PartnerOption(value: 'SECURITY', label: 'Охрана/безопасность'),
    PartnerOption(value: 'RAIL', label: 'Ж/д перевозки'),
    PartnerOption(value: 'AIR', label: 'Авиаперевозки'),
    PartnerOption(value: 'PORT', label: 'Морские линии/порты'),
    PartnerOption(value: 'OTHER', label: 'Другое'),
  ];

  static List<PartnerOption> get countries => [
    PartnerOption(value: 'KZ', label: 'Казахстан'),
    PartnerOption(value: 'RU', label: 'Россия'),
    PartnerOption(value: 'KG', label: 'Кыргызстан'),
    PartnerOption(value: 'UZ', label: 'Узбекистан'),
    PartnerOption(value: 'TJ', label: 'Таджикистан'),
    PartnerOption(value: 'TM', label: 'Туркменистан'),
    PartnerOption(value: 'BY', label: 'Беларусь'),
    PartnerOption(value: 'AM', label: 'Армения'),
    PartnerOption(value: 'AZ', label: 'Азербайджан'),
    PartnerOption(value: 'MD', label: 'Молдова'),
    PartnerOption(value: 'UA', label: 'Украина'),
    PartnerOption(value: 'CN', label: 'Китай'),
    PartnerOption(value: 'TR', label: 'Турция'),
    PartnerOption(value: 'AE', label: 'ОАЭ'),
    PartnerOption(value: 'OTHER', label: 'Другое'),
  ];
}
