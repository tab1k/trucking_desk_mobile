import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/driver/providers/driver_favorites_provider.dart';

Future<void> toggleDriverOrderFavorite(
  BuildContext context,
  WidgetRef ref,
  OrderSummary order,
) async {
  final repository = ref.read(orderRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (order.isFavoriteForDriver) {
      await repository.removeDriverFavorite(order.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Удалено из избранного')),
      );
    } else {
      await repository.addDriverFavorite(order.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Добавлено в избранное')),
      );
    }
    ref.invalidate(driverFavoritesProvider);
  } on ApiException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Не удалось обновить избранное')),
    );
  }
}

Future<void> callOrderSender(
  BuildContext context,
  OrderSummary order,
) async {
  if (!order.canDriverCall) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отправитель не раскрыл контакты')),
    );
    return;
  }
  final phone = order.senderPhoneNumber.trim();
  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Телефон отправителя недоступен')),
    );
    return;
  }
  final uri = Uri(scheme: 'tel', path: phone);
  try {
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть звонилку')),
      );
      return;
    }
    await launchUrl(uri);
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось позвонить отправителю')),
    );
  }
}
