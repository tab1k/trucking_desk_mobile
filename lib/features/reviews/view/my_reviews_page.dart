import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fura24.kz/features/reviews/domain/models/review.dart';
import 'package:fura24.kz/features/reviews/providers/my_reviews_provider.dart';

class MyReviewsPage extends ConsumerWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsProvider);

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
            tr('profile.my_reviews'),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: reviewsAsync.when(
          data: (reviews) => _ReviewsList(
            reviews: reviews,
            onRefresh: () => ref.refresh(myReviewsProvider.future),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr('common.error'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: () => ref.refresh(myReviewsProvider),
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  const _ReviewsList({required this.reviews, required this.onRefresh});

  final List<Review> reviews;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          children: [
            SizedBox(height: 120.h),
            Center(
              child: Text(
                'У вас пока нет отзывов',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: reviews.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          return _ReviewCard(review: reviews[index]);
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundImage: review.senderPhoto != null
                    ? NetworkImage(review.senderPhoto!)
                    : null,
                backgroundColor: Colors.grey[200],
                child: review.senderPhoto == null
                    ? Icon(Icons.person, color: Colors.grey, size: 24.r)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.senderName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16.r,
                          color: const Color(0xFFFFB800),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('dd.MM.yyyy').format(review.createdAt),
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
