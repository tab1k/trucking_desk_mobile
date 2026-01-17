import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/reviews/domain/models/review.dart';
import 'package:fura24.kz/features/reviews/repositories/review_repository.dart';

final myReviewsProvider = FutureProvider.autoDispose<List<Review>>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getMyReviews();
});
