import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';
import 'package:fura24.kz/router/routes.dart';

// Tariff Types (matching backend)
class TariffType {
  static const String city = 'CITY';
  static const String intercity = 'INTERCITY';
  static const String international = 'INTERNATIONAL';
}

/// Checks if driver can perform actions (Bid/Call).
/// Returns true if allowed, false if blocked (and shows dialog/snack).
Future<bool> ensureDriverActionAllowed(
  BuildContext context,
  WidgetRef ref, {
  OrderSummary? orderForTariffCheck,
}) async {
  final user = ref.read(currentUserProvider);

  if (user == null) {
    _showSnack(context, tr('driver_utils.authorize_as_driver'));
    return false;
  }
  if (user.role.toUpperCase() != 'DRIVER') {
    _showSnack(context, tr('driver_utils.drivers_only'));
    return false;
  }

  // 1. Verification Check
  if (user.verificationStatus != 'APPROVED') {
    await _showVerificationDialog(context);
    return false;
  }

  // 2. Subscription Check
  if (!user.isSubscriptionActive) {
    _showSnack(context, tr('driver_utils.subscription_required'));
    // TODO: Maybe redirect to subscription page?
    return false;
  }

  // 3. Tariff Compatibility Check (if order is provided)
  if (orderForTariffCheck != null) {
    final tariffError = _checkTariff(user.tariffPlan, orderForTariffCheck);
    if (tariffError != null) {
      _showSnack(context, tariffError);
      return false;
    }
  }

  return true;
}

String? _checkTariff(String? userTariff, OrderSummary order) {
  if (userTariff == null)
    return null; // Should be covered by subscription check usually

  final cities = <String>{
    order.departureCity.trim().toLowerCase(),
    order.destinationCity.trim().toLowerCase(),
    for (final wp in order.waypoints)
      if (wp.location['city_name'] != null)
        (wp.location['city_name'] as String).trim().toLowerCase(),
  };

  final isSingleCity = cities.length == 1;

  switch (userTariff) {
    case TariffType.city:
      if (!isSingleCity) {
        return tr('driver_utils.tariff_error_city_only');
      }
      break;
    case TariffType.intercity:
    case TariffType.international:
      if (isSingleCity) {
        return tr('driver_utils.tariff_error_local_forbidden');
      }
      break;
  }

  // Note: We can't easily check "Country" on mobile without rich location data.
  // But strictly blocked "Same City" for Intercity/International is a good start.

  return null;
}

Future<void> _showVerificationDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                tr('driver_utils.verification_needed_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                tr('driver_utils.verification_needed_body'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(tr('driver_utils.later')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ctx.go(DriverRoutes.verification);
                      },
                      child: Text(tr('driver_utils.verify')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
