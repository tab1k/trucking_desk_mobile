import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/reviews/domain/models/pending_review.dart';
import 'package:fura24.kz/features/reviews/repositories/review_repository.dart';

final pendingReviewProvider = FutureProvider.autoDispose<PendingReview?>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getPendingReview();
});
