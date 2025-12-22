import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key, required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final content = _agreementContent(locale);
    final textStyle = TextStyle(fontSize: 14.sp, height: 1.45, color: Colors.black87);
    final headingStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    );

    return Scaffold(
      appBar: SingleAppbar(
        title: tr(titleKey),
        onBack: () => Navigator.of(context).pop(),
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

  _AgreementContent _agreementContent(String lang) {
    switch (lang) {
      case 'kk':
        return _AgreementContent(
          heading: 'Пайдаланушы келісімі',
          sections: [
            _AgreementSection(
              title: 'Кіріспе',
              paragraphs: [
                'Бұл шарттар сіздің Fura24.kz платформасына қол жеткізуіңізді және пайдалануыңызды реттейді. Жеке деректерді пайдалану Құпиялылық саясатында, cookie файлдарын пайдалану Cookie саясатында сипатталған. «Fura24.kz» — «Aspan Cargo» ЖШС.',
              ],
            ),
            _AgreementSection(
              title: 'Қолдану саласы',
              paragraphs: [
                'Fura24.kz — жүк жариялайтын Тапсырыс берушілер мен көлік ұсынатын Тасымалдаушылар үшін онлайн биржа. Біз Груз/Көлікке иелік етпейміз және келісімшарттардың тарапы емеспіз, басқа сервистерге сілтемелер үшін де жауап бермейміз.',
              ],
            ),
            _AgreementSection(
              title: 'Шарттарды өзгерту',
              paragraphs: [
                'Шарттар жаңартылуы мүмкін; платформаны әрі қарай пайдалану жаңартуларды қабылдауды білдіреді.',
              ],
            ),
            _AgreementSection(
              title: 'Тіркеу',
              paragraphs: [
                'Груз/Көлік жариялау үшін аккаунт қажет. Компания атынан тіркелсеңіз, өкілеттілігіңізді растайсыз. Деректерді дұрыс көрсетіңіз және қорғаңыз; аккаунт бойынша әрекеттер үшін жауап бересіз.',
              ],
            ),
            _AgreementSection(
              title: 'Контент',
              paragraphs: [
                'Пайдаланушылар мәтін, фото және басқа контент жариялай алады. Сіз Fura24.kz-ке платформаны қолдау және жарнамалау үшін айрықша емес лицензия бересіз. Заңсыз немесе зиянды контент жойылуы мүмкін.',
              ],
            ),
            _AgreementSection(
              title: 'Төлемдер',
              paragraphs: [
                'Кейбір қызметтер ақылы; төлем 14 күн ішінде, егер ақылы сервис қолданылмаса, қайтарылады.',
              ],
            ),
            _AgreementSection(
              title: 'Тыйым салынған әрекеттер',
              bullets: [
                'Заңдарды, үшінші тұлғалардың құқықтарын немесе Шарттарды бұзу.',
                'Спам тарату.',
                'Құқығыңыз жоқ Груз/Көлікті жариялау.',
                'Пайдаланушылармен тасымалдауға қатысы жоқ мақсатта байланысу.',
                'Fura24.kz бренді мен дизайнын рұқсатсыз пайдалану.',
                'Деректерді жинау үшін автоматтандырылған құралдарды қолдану.',
                'Қорғаныс шараларын айналып өту немесе кері инженерия.',
                'Платформаның жұмысына кедергі келтіру.',
              ],
              paragraphs: [
                'Fura24.kz заңды сақтау және қауіпсіздік үшін қолжетімділікті шектеуі, контентті жоюы немесе аккаунттарды тоқтатуы мүмкін.',
              ],
            ),
            _AgreementSection(
              title: 'Мерзім және тоқтату',
              paragraphs: [
                'Келісім 30 күнге жасалады және автоматты түрде ұзартылып отырады. Сіз немесе Fura24.kz оны тоқтата аласыз; елеулі бұзушылықтар болса қолжетімділік шектелуі мүмкін.',
              ],
            ),
            _AgreementSection(
              title: 'Кепілдіктерден бас тарту және жауапкершілік',
              paragraphs: [
                'Платформа «қалай бар» қағидасымен ұсынылады, тәуекел өзіңізде. Заң рұқсат ететін шекте Fura24.kz жанама шығындар мен пайдаланушылардың әрекеттері үшін жауапты емес.',
              ],
            ),
          ],
        );
      case 'en':
        return _AgreementContent(
          heading: 'User Agreement',
          sections: [
            _AgreementSection(
              title: 'Introduction',
              paragraphs: [
                'These Terms govern your access to and use of the Fura24.kz platform. Personal data use is described in the Privacy Policy; cookies are described in the Cookie Policy. “Fura24.kz” refers to Aspan Cargo LLP.',
              ],
            ),
            _AgreementSection(
              title: 'Scope',
              paragraphs: [
                'Fura24.kz is a freight marketplace where Shippers post cargo and Carriers offer transport. We do not own or control cargo/transport and are not a party to user contracts. We are not responsible for third-party services linked from the platform.',
              ],
            ),
            _AgreementSection(
              title: 'Changes',
              paragraphs: [
                'Terms may be updated; continued use means acceptance of the changes.',
              ],
            ),
            _AgreementSection(
              title: 'Registration',
              paragraphs: [
                'An account is required to post cargo or transport. If registering for a company, you confirm authority. Provide accurate data, keep credentials safe, and you are responsible for actions under your account.',
              ],
            ),
            _AgreementSection(
              title: 'Content',
              paragraphs: [
                'Users may post text, photos, and other content. You grant Fura24.kz a non-exclusive license to use it to operate and promote the Platform (in line with data laws). Illegal or harmful content may be removed.',
              ],
            ),
            _AgreementSection(
              title: 'Payments',
              paragraphs: [
                'Some services are paid; payments can be refunded within 14 days if paid services were not used.',
              ],
            ),
            _AgreementSection(
              title: 'Prohibited actions',
              bullets: [
                'Breaking laws, third-party rights, or these Terms.',
                'Sending spam.',
                'Posting cargo/transport you have no right to handle.',
                'Contacting users for purposes unrelated to transport.',
                'Using Fura24.kz brand/design without consent.',
                'Using automated tools to scrape data.',
                'Bypassing security or reverse engineering.',
                'Harming platform operation.',
              ],
              paragraphs: [
                'Fura24.kz may limit access, remove content, or suspend accounts to comply with law and protect users.',
              ],
            ),
            _AgreementSection(
              title: 'Term and termination',
              paragraphs: [
                'The Agreement lasts 30 days and auto-renews. You or Fura24.kz may terminate; access can be suspended for violations.',
              ],
            ),
            _AgreementSection(
              title: 'Disclaimer and liability',
              paragraphs: [
                'The Platform is provided “as is”; you use it at your own risk. To the extent allowed by law, Fura24.kz is not liable for indirect losses or user behavior.',
              ],
            ),
          ],
        );
      case 'zh':
        return _AgreementContent(
          heading: '用户协议',
          sections: [
            _AgreementSection(
              title: '引言',
              paragraphs: [
                '本条款规范您对 Fura24.kz 平台的访问与使用。个人数据的使用见隐私政策，Cookie 的使用见 Cookie 政策。“Fura24.kz”指 Aspan Cargo LLP。',
              ],
            ),
            _AgreementSection(
              title: '适用范围',
              paragraphs: [
                'Fura24.kz 是一个货运信息平台，托运人发布货物，承运人提供运输。我们不拥有或控制货物/运输，也不是用户合同的一方，对第三方服务不承担责任。',
              ],
            ),
            _AgreementSection(
              title: '条款变更',
              paragraphs: [
                '条款可能更新；继续使用即表示接受修改。',
              ],
            ),
            _AgreementSection(
              title: '注册',
              paragraphs: [
                '发布货物或运输需要账户。如代表公司注册，需确认授权。提供准确信息、妥善保管凭据，并对账户行为负责。',
              ],
            ),
            _AgreementSection(
              title: '内容',
              paragraphs: [
                '用户可发布文本、照片等内容，并授予 Fura24.kz 非独占许可用于平台运营和推广（遵守数据法律）。违法或有害内容可被移除。',
              ],
            ),
            _AgreementSection(
              title: '付款',
              paragraphs: [
                '部分服务需付费；若未使用付费服务，付款可在14天内退款。',
              ],
            ),
            _AgreementSection(
              title: '禁止行为',
              bullets: [
                '违反法律、第三方权利或本条款。',
                '发送垃圾信息。',
                '发布无权处理的货物/运输。',
                '为非运输目的联系用户。',
                '未经同意使用 Fura24.kz 品牌/设计。',
                '使用自动化工具抓取数据。',
                '绕过安全措施或逆向工程。',
                '损害平台运行。',
              ],
              paragraphs: [
                'Fura24.kz 可限制访问、移除内容或暂停账户，以守法并保护用户。',
              ],
            ),
            _AgreementSection(
              title: '期限与终止',
              paragraphs: [
                '协议为30天并自动续期。您或 Fura24.kz 可终止；违反条款时访问可被暂停。',
              ],
            ),
            _AgreementSection(
              title: '免责声明与责任',
              paragraphs: [
                '平台按“原样”提供，使用风险自担。在法律允许范围内，Fura24.kz 对间接损失或用户行为不承担责任。',
              ],
            ),
          ],
        );
      default:
        return _AgreementContent(
          heading: 'Пользовательское соглашение',
          sections: [
            _AgreementSection(
              title: 'Вступление',
              paragraphs: [
                'Настоящие Условия — юридически обязывающее соглашение между вами и Fura24.kz, регулирующее доступ и использование веб‑сайта и приложения Fura24.kz, дочерних доменов и иных сервисов Fura24.kz.',
                'Сбор и использование личной информации описаны в Политике конфиденциальности; cookie — в Политике Cookie. «Fura24.kz», «мы», «нас», «наш» — ТОО «Aspan Cargo».',
              ],
            ),
            _AgreementSection(
              title: 'Сфера применения',
              paragraphs: [
                'Fura24.kz — онлайн биржа грузов для Заказчиков (владельцев грузов) и Перевозчиков (услуги по перевозке), где публикуются Грузы и Транспорт.',
                'Fura24.kz не владеет, не создает, не продает и не управляет Грузами/Транспортом и не является стороной договоров между Пользователями; не является владельцем, экспедитором, брокером или страховщиком.',
                'Мы можем помогать в разрешении споров, но не контролируем и не гарантируем наличие, качество, безопасность, пригодность или законность Грузов/Транспорта, точность описаний, рейтингов и действий Пользователей.',
                'Платформа может содержать ссылки на сторонние сервисы; мы не отвечаем за их доступность, достоверность, содержимое или услуги. Доступ может ограничиваться для безопасности и обслуживания; сервис может улучшаться и модифицироваться.',
              ],
            ),
            _AgreementSection(
              title: 'Изменение условий',
              paragraphs: [
                'Fura24.kz может изменять Условия, публикуя обновления. Если вы не согласны, можете расторгнуть Соглашение; продолжение использования означает принятие новых условий.',
              ],
            ),
            _AgreementSection(
              title: 'Регистрация',
              paragraphs: [
                'Для публикации Грузов или Транспорта нужна учетная запись Fura24.kz. Регистрируясь от имени организации, вы подтверждаете полномочия.',
                'Нужно указывать точные и актуальные данные и обновлять их; разрешена одна учетная запись, если иное не согласовано. Передача аккаунта третьим лицам запрещена.',
                'Вы отвечаете за конфиденциальность учетных данных и должны немедленно уведомить о потере/компрометации. Вы несете ответственность за действия с аккаунтом, если не проявили должную осмотрительность.',
                'Проверка личности сложна; мы можем (но не обязаны) запрашивать удостоверение личности или проводить дополнительные проверки по базам данных или отчетам третьих лиц.',
              ],
            ),
            _AgreementSection(
              title: 'Содержимое',
              paragraphs: [
                'Пользователи могут создавать, загружать и хранить Пользовательский контент (текст, фото, аудио, видео и др.) и просматривать Контент Fura24.kz или лицензированный контент третьих лиц.',
                'Платформа, Контент Fura24.kz и Пользовательский контент могут быть защищены авторским правом и товарными знаками; нельзя удалять уведомления о правах.',
                'Размещая Пользовательский контент, вы предоставляете Fura24.kz неисключительную, всемирную, безвозмездную, безотзывную, сублицензируемую и передаваемую лицензию на использование для работы и продвижения Платформы (с соблюдением законов о данных).',
                'Вы заявляете, что обладаете правами на контент и что его использование не нарушает права третьих лиц или закон. Незаконный или вредный контент может быть удален без уведомления. Запрещено размещать мошеннический, вводящий в заблуждение, клеветнический, непристойный, разжигающий ненависть или пропагандирующий насилие/незаконные действия контент.',
              ],
            ),
            _AgreementSection(
              title: 'Платежи',
              paragraphs: [
                'Некоторые услуги платные; сумма зависит от объема услуг. Платеж может быть возвращен в течение 14 дней, если платные сервисы не использовались.',
              ],
            ),
            _AgreementSection(
              title: 'Запрещенные действия',
              paragraphs: [
                'Вы несете ответственность за соблюдение законов и налоговых обязательств. Запрещается:',
              ],
              bullets: [
                'Нарушать или обходить законы, права третьих лиц или Условия.',
                'Использовать Fura24.kz в связи с распространением спама.',
                'Публиковать Грузы/Транспорт без права распоряжаться ими через Платформу.',
                'Связываться с пользователями вне целей, связанных с Грузами или Транспортом.',
                'Использовать, отображать, зеркалить или фреймить Платформу/бренд/знаки Fura24.kz без письменного согласия.',
                'Разбавлять или вредить бренду Fura24.kz (в т.ч. через домены/знаки, схожие до смешения).',
                'Использовать роботов, пауков, сканеры, парсеры или другие автоматизированные средства для доступа и сбора данных.',
                'Обходить, удалять, деактивировать или иным образом пытаться обойти технические меры защиты.',
                'Пытаться расшифровать, декомпилировать, дизассемблировать или перепроектировать ПО Платформы.',
                'Предпринимать действия, вредящие работе или функционированию Платформы.',
                'Нарушать или нарушать чужие права или причинять вред.',
              ],
              paragraphsAfterBullets: [
                'Fura24.kz может контролировать доступ, удалять контент, ограничивать учетные записи для работы, безопасности и соблюдения закона; Пользователи обязаны сотрудничать и предоставлять информацию по запросу.',
              ],
            ),
            _AgreementSection(
              title: 'Срок и прекращение',
              paragraphs: [
                'Соглашение действует 30 дней и автоматически продлевается, пока не прекращено вами или Fura24.kz. Вы можете прекратить, отправив уведомление; связанные Грузы/Транспорт будут удалены.',
                'Fura24.kz может прекратить по удобству или немедленно при существенном нарушении, нарушении закона или для защиты безопасности.',
              ],
              bullets: [
                'Отказ публиковать, архивировать или удалять Грузы/Транспорт/контент.',
                'Ограничение доступа или использования Платформы.',
                'Отзыв специального статуса аккаунта.',
                'Временная или постоянная приостановка аккаунта и доступа к Платформе.',
              ],
              paragraphsAfterBullets: [
                'После прекращения аккаунт и контент не восстанавливаются; нельзя регистрировать новый аккаунт, если предыдущий приостановлен или прекращен.',
              ],
            ),
            _AgreementSection(
              title: 'Отказ от гарантий',
              paragraphs: [
                'Используя Платформу, вы делаете это добровольно и на свой риск. Платформа предоставляется «как есть», без явных или подразумеваемых гарантий. Проверки пользователей не гарантируют отсутствие прошлых нарушений или будущего недобросовестного поведения.',
              ],
            ),
            _AgreementSection(
              title: 'Ответственность',
              paragraphs: [
                'В максимально допустимой законом степени риск использования Платформы и взаимодействия с пользователями остается на вас. Fura24.kz не несет ответственности за косвенные убытки, упущенную выгоду, потерю данных или репутации, сбои работы, а также за ущерб от взаимодействий с другими пользователями.',
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

class _AgreementContent {
  const _AgreementContent({required this.heading, required this.sections});
  final String heading;
  final List<_AgreementSection> sections;
}

class _AgreementSection {
  const _AgreementSection({
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
