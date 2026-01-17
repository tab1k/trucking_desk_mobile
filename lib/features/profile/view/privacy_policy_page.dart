import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key, required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final content = _policyContent(locale);
    final textStyle = TextStyle(
      fontSize: 14.sp,
      height: 1.45,
      color: Colors.black87,
    );
    final headingStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    );

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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Text(
            tr(titleKey),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content.heading, style: headingStyle),
              SizedBox(height: 10.h),
              ...content.sections.expand((section) sync* {
                yield Text(section.title, style: headingStyle);
                yield SizedBox(height: 8.h);
                for (final p in section.paragraphs) {
                  yield Text(p, style: textStyle);
                  yield SizedBox(height: 10.h);
                }
                if (section.bullets.isNotEmpty) {
                  yield* _bullets(section.bullets, textStyle);
                  yield SizedBox(height: 10.h);
                }
                for (final p in section.paragraphsAfterBullets) {
                  yield Text(p, style: textStyle);
                  yield SizedBox(height: 10.h);
                }
                yield SizedBox(height: 6.h);
              }),
            ],
          ),
        ),
      ),
    );
  }

  _PolicyContent _policyContent(String lang) {
    switch (lang) {
      case 'kk':
        return _PolicyContent(
          heading: 'Құпиялылық саясаты',
          sections: [
            _PolicySection(
              title: 'Кіріспе',
              paragraphs: [
                'Белгіленбеген терминдер (мысалы, «Груз» немесе «Fura24.kz платформасы») Пайдаланушы келісіміндегі анықтамаларға сәйкес келеді. Бұл саясат Fura24.kz платформасын қолданғанда жеке деректерді қалай жинайтынымызды, қолданатынымызды және ашатынымызды сипаттайды.',
              ],
            ),
            _PolicySection(
              title: 'Қандай ақпарат жинаймыз?',
              paragraphs: ['Сіз беретін ақпарат:'],
              bullets: [
                'Аккаунт деректері: аты-жөні, e-mail және т.б.',
                'Fura24.kz және пайдаланушылармен хат алмасу мазмұны.',
                'Байланыс деректері: жарияланған жүк/көлікте қосымша контактылар.',
              ],
            ),
            _PolicySection(
              title: 'Автоматты жиналатын ақпарат',
              bullets: [
                'Геолокация (IP немесе GPS, құрылғы баптауларымен басқарылады).',
                'Пайдалану деректері: қаралған беттер, іздеу әрекеттері.',
                'Журналдар мен құрылғы деректері: IP, уақыт, құрылғы/ПО туралы мәлімет, cookie.',
                'Cookie және ұқсас технологиялар: аналитика және оңтайландыру үшін.',
              ],
            ),
            _PolicySection(
              title: 'Ақпаратты қалай қолданамыз',
              paragraphs: ['Платформаны ұсыну, жақсарту және дамыту үшін:'],
              bullets: [
                'Қолжетімділік, байланыс, қолдау хабарламалары.',
                'Қауіпсіздік, зерттеулер және оңтайландыру.',
                'Төленетін қызметтерге қол жеткізу.',
              ],
            ),
            _PolicySection(
              title: 'Қауіпсіз орта құру',
              bullets: [
                'Алаяқтық, спам және теріс пайдалануды анықтау/болдырмау.',
                'Қауіпсіздік тексерістері мен тәуекелдерді бағалау.',
                'Заң талаптарын орындау; қорғау мақсатында профилдеу.',
              ],
            ),
            _PolicySection(
              title: 'Жарнама және маркетинг',
              bullets: [
                'Таңдауларға сәйкес жарнамалық хабарламалар жіберу.',
                'Жарнаманы жекелеу және өлшеу, соның ішінде соцжелілерде.',
                'Қызығушылықтар мен пайдалану тарихына қарай профилдеу.',
              ],
            ),
            _PolicySection(
              title: 'Ақпаратты бөлісу',
              paragraphs: [
                'Пайдаланушылар арасында: жүк/көлік жариялағанда тапсырыс беруші мен тасымалдаушы профиль, аты және контактілерді көреді. Төлем деректері берілмейді.',
                'Заңды сақтау: соттарға, құқық қорғау немесе уәкілетті органдарға заң бойынша деректерді беруіміз мүмкін; хабарлау заңмен шектелуі мүмкін.',
                'Қызмет көрсетушілер: тексеру, алаяқтықтың алдын алу, әзірлеу, төлем, жарнама үшін тартылады; деректерге шектеулі қол жеткізеді және оларды қорғауға міндетті.',
              ],
            ),
          ],
        );
      case 'en':
        return _PolicyContent(
          heading: 'Privacy Policy',
          sections: [
            _PolicySection(
              title: 'Introduction',
              paragraphs: [
                'Undefined terms (e.g., “Cargo” or “Fura24.kz Platform”) have the meanings from the User Agreement. This policy explains how we collect, use, process, and disclose personal data when you access and use Fura24.kz.',
              ],
            ),
            _PolicySection(
              title: 'What information we collect',
              paragraphs: ['Information you provide:'],
              bullets: [
                'Account info: name, surname, email, etc. when creating an account.',
                'Communication with Fura24.kz and other users.',
                'Contact info added to cargo/transport listings.',
              ],
            ),
            _PolicySection(
              title: 'Automatically collected',
              bullets: [
                'Geolocation (IP or GPS; controllable in device settings).',
                'Usage info: pages viewed, searches, actions.',
                'Logs/device data: IP, access time, device/OS info, events, cookies.',
                'Cookies and similar tech for analytics and optimization.',
              ],
            ),
            _PolicySection(
              title: 'How we use information',
              paragraphs: ['To provide, improve, and develop the platform:'],
              bullets: [
                'Access and communication with users; support messages.',
                'Security, research, and optimization.',
                'Access to paid services.',
              ],
            ),
            _PolicySection(
              title: 'Keeping a safe environment',
              bullets: [
                'Detect and prevent fraud, spam, abuse.',
                'Security checks and risk assessment.',
                'Legal compliance; profiling to protect the platform.',
              ],
            ),
            _PolicySection(
              title: 'Advertising and marketing',
              bullets: [
                'Send promotional messages based on preferences.',
                'Personalize and measure ads, including in social media.',
                'Profile by interests and usage history.',
              ],
            ),
            _PolicySection(
              title: 'Sharing and disclosure',
              paragraphs: [
                'Between users: when cargo/transport is posted, shippers and carriers see each other’s profile, name, and contacts; payment data is not shared.',
                'Legal compliance: we may disclose data to courts, law enforcement, or authorities as required; notice may be limited by law.',
                'Service providers: engaged for verification, fraud prevention, development, payments, and ads; they have limited access and must protect data.',
              ],
            ),
          ],
        );
      case 'zh':
        return _PolicyContent(
          heading: '隐私政策',
          sections: [
            _PolicySection(
              title: '引言',
              paragraphs: [
                '未定义术语（如“货物”或“Fura24.kz 平台”）与用户协议中的定义一致。本政策说明在您使用 Fura24.kz 时我们如何收集、使用、处理和披露个人信息。',
              ],
            ),
            _PolicySection(
              title: '我们收集哪些信息',
              paragraphs: ['您提供的信息：'],
              bullets: [
                '账户信息：姓名、邮箱等。',
                '与 Fura24.kz 及其他用户的通信内容。',
                '在货物/运输中添加的联系信息。',
              ],
            ),
            _PolicySection(
              title: '自动收集的信息',
              bullets: [
                '地理位置（IP 或 GPS，可在设备设置中控制）。',
                '使用信息：浏览的页面、搜索与操作。',
                '日志/设备数据：IP、访问时间、设备/系统信息、事件、cookie。',
                'Cookie 及类似技术用于分析和优化。',
              ],
            ),
            _PolicySection(
              title: '信息用途',
              paragraphs: ['为了提供、改进和发展平台：'],
              bullets: ['访问与用户沟通，发送支持消息。', '安全、防护、研究与优化。', '提供付费服务的访问。'],
            ),
            _PolicySection(
              title: '安全环境',
              bullets: ['发现和防止欺诈、垃圾信息与滥用。', '安全检查与风险评估。', '遵守法律；为保护平台进行画像分析。'],
            ),
            _PolicySection(
              title: '广告与营销',
              bullets: ['根据偏好发送促销信息。', '个性化并衡量广告效果（含社交媒体）。', '基于兴趣和使用历史进行画像。'],
            ),
            _PolicySection(
              title: '共享与披露',
              paragraphs: [
                '用户之间：发布货物/运输时，托运人与承运人可见彼此的资料、姓名和联系方式；支付数据不会共享。',
                '遵守法律：可依法向法院、执法或主管机关披露数据；通知可能受法律限制。',
                '服务提供方：用于验证、防欺诈、开发、支付和广告；仅限必要访问并须保护数据。',
              ],
            ),
          ],
        );
      default:
        return _PolicyContent(
          heading: 'Политика конфиденциальности',
          sections: [
            _PolicySection(
              title: 'Вступление',
              paragraphs: [
                'Если вы видите неопределенный термин (например, «Груз» или «Платформа Fura24.kz»), он имеет то же определение, что и в Пользовательском соглашении. Настоящая политика описывает, как мы собираем, используем, обрабатываем и раскрываем личную информацию в связи с доступом и использованием Платформы Fura24.kz и всех сайтов/служб, которые на нее ссылаются.',
              ],
            ),
            _PolicySection(
              title: 'Какую информацию мы собираем',
              paragraphs: [
                'Информация, которую вы предоставляете (необходима для исполнения договора и законных обязательств):',
              ],
              bullets: [
                'Информация учетной записи: имя, фамилия, e-mail и др. при создании аккаунта.',
                'Общение с Fura24.kz и пользователями: сведения о переписке и переданной информации.',
                'Контактная информация: дополнительные контакты в грузах/транспорте для связи с вами.',
              ],
              paragraphsAfterBullets: [
                'Без этих данных мы не сможем предоставить запрошенные услуги.',
              ],
            ),
            _PolicySection(
              title: 'Автоматически собираемая информация',
              bullets: [
                'Геолокация: точное или приблизительное местоположение по IP или GPS (можно управлять в настройках устройства).',
                'Информация об использовании: просмотренные страницы/контент, поиск грузов/транспорта, действия на платформе.',
                'Журналы и данные устройства: IP-адрес, дата и время доступа, сведения об устройстве/ПО, события на устройстве, уникальные идентификаторы, данные cookie и посещенные страницы.',
                'Cookie и подобные технологии: файлы cookie, веб-маяки, пиксели, журналы серверов и мобильные идентификаторы; чаще как обезличенные данные, но иногда связываются с персональными.',
              ],
              paragraphs: [
                'Эти данные нужны для исполнения договора, соблюдения закона и нашей законной заинтересованности в работе и улучшении функционала Платформы Fura24.kz.',
              ],
            ),
            _PolicySection(
              title: 'Как используем информацию',
              paragraphs: [
                'Предоставляем, улучшаем и развиваем Платформу Fura24.kz:',
              ],
              bullets: [
                'Предоставление доступа и использования Платформы.',
                'Связь между пользователями.',
                'Эксплуатация, защита, улучшение и оптимизация, включая анализ и исследования.',
                'Обслуживание клиентов.',
                'Сообщения службы поддержки, обновления, уведомления о безопасности и аккаунте.',
                'Доступ к платным услугам.',
              ],
            ),
            _PolicySection(
              title: 'Надежная среда',
              bullets: [
                'Обнаружение и предотвращение мошенничества, спама, злоупотреблений.',
                'Расследования безопасности и оценка рисков.',
                'Проверка и подтверждение предоставленных данных и идентификации.',
                'Проверки по базам данных, включая биографические/полицейские проверки, если допускается законом и с вашего согласия, где требуется.',
                'Соблюдение юридических обязательств.',
                'Профилирование на основе взаимодействия с платформой и данных профиля для защиты и оценки рисков.',
              ],
              paragraphs: [
                'Обрабатываем данные с учетом законной заинтересованности в защите Платформы Fura24.kz, надлежащем исполнении договора и соблюдении применимых законов.',
              ],
            ),
            _PolicySection(
              title: 'Реклама и маркетинг',
              bullets: [
                'Отправка рекламных, маркетинговых сообщений по вашим предпочтениям (включая кампании Fura24.kz и партнеров) и реклама в соцсетях.',
                'Персонализация, измерение и улучшение рекламы.',
                'Профилирование по характеристикам и предпочтениям (по вашим данным, взаимодействиям, данным третьих лиц и истории поиска).',
              ],
              paragraphs: [
                'Обрабатываем данные, опираясь на законную заинтересованность в маркетинге, чтобы предлагать актуальные продукты и услуги.',
              ],
            ),
            _PolicySection(
              title: 'Обмен и раскрытие',
              paragraphs: [
                'Обмен между пользователями: при публикации грузов или транспорта передается профиль, имя, контактная информация и иные данные, которыми вы делитесь. Платежные данные не передаются другим участникам.',
                'Соблюдение закона, ответы на запросы и защита прав: можем раскрывать данные судам, правоохранительным, гос- и налоговым органам или уполномоченным третьим лицам для соблюдения закона, ответов на претензии, расследований незаконной деятельности, защиты прав и безопасности Fura24.kz и пользователей. Уведомление может быть ограничено законом или риском злоупотреблений.',
                'Поставщики услуг: привлекаем сторонних провайдеров (в т.ч. за пределами ЕЭЗ) для проверки личности, предотвращения мошенничества, разработки, обслуживания, интеграций, клиентской поддержки, рекламы, платежей и обработки претензий. Они имеют ограниченный доступ и обязаны защищать данные и использовать их только по нашим инструкциям.',
              ],
            ),
          ],
        );
    }
  }

  List<Widget> _bullets(List<String> items, TextStyle style) {
    return items
        .map(
          (text) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: style),
                Expanded(child: Text(text, style: style)),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _PolicyContent {
  const _PolicyContent({required this.heading, required this.sections});
  final String heading;
  final List<_PolicySection> sections;
}

class _PolicySection {
  const _PolicySection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
    this.paragraphsAfterBullets = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<String> paragraphsAfterBullets;
}
