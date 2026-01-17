import 'package:easy_localization/easy_localization.dart';
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
        SnackBar(content: Text(tr('driver_utils.removed_favorite'))),
      );
    } else {
      await repository.addDriverFavorite(order.id);
      messenger.showSnackBar(
        SnackBar(content: Text(tr('driver_utils.added_favorite'))),
      );
    }
    ref.invalidate(driverFavoritesProvider);
  } on ApiException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(tr('driver_utils.update_favorite_error'))),
    );
  }
}

Future<void> callOrderSender(BuildContext context, OrderSummary order) async {
  if (!order.canDriverCall) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('driver_utils.contacts_hidden'))));
    return;
  }
  final phone = order.senderPhoneNumber.trim();
  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('driver_utils.phone_unavailable'))),
    );
    return;
  }
  final uri = Uri(scheme: 'tel', path: phone);
  try {
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('driver_utils.dialer_error'))));
      return;
    }
    await launchUrl(uri);
  } catch (_) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('driver_utils.call_error'))));
  }
}

Future<void> openOrderWhatsApp(BuildContext context, OrderSummary order) async {
  if (!order.canDriverCall) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('driver_utils.contacts_hidden'))));
    return;
  }
  final phone = order.senderPhoneNumber.trim();
  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('driver_utils.phone_unavailable'))),
    );
    return;
  }

  // Remove all non-digit characters for the link
  final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
  final uri = Uri.parse('https://wa.me/$cleanPhone');

  try {
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('driver_utils.whatsapp_error'))),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('driver_utils.whatsapp_error'))));
  }
}
