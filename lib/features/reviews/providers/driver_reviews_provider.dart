import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/reviews/domain/models/review.dart';
import 'package:fura24.kz/features/reviews/repositories/review_repository.dart';

final driverReviewsProvider = FutureProvider.autoDispose
    .family<List<Review>, String>((ref, driverId) {
      final repository = ref.watch(reviewRepositoryProvider);
      return repository.getDriverReviews(driverId);
    });
