import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/business/data/models/partner_model.dart';
import 'package:fura24.kz/features/business/data/repositories/partner_repository.dart';

// Provides the list of partners, optionally filtered by city
final partnersProvider = FutureProvider.family<List<PartnerModel>, String?>((
  ref,
  city,
) async {
  final repository = ref.watch(partnerRepositoryProvider);
  return repository.getPartners(city: city);
});
