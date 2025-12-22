import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/driver/providers/responded_orders_provider.dart';

Future<bool?> showDriverRespondSheet(BuildContext context, OrderSummary order) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _DriverRespondSheet(order: order),
  );
}

class _DriverRespondSheet extends ConsumerStatefulWidget {
  const _DriverRespondSheet({required this.order});

  final OrderSummary order;

  @override
  ConsumerState<_DriverRespondSheet> createState() =>
      _DriverRespondSheetState();
}

class _DriverRespondSheetState extends ConsumerState<_DriverRespondSheet> {
  final _commentController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;
  bool _showAmountField = false;

  @override
  void initState() {
    super.initState();
    final orderAmount = widget.order.amountValue;
    if (orderAmount != null && orderAmount > 0) {
      _amountController.text = orderAmount.toStringAsFixed(
        orderAmount == orderAmount.roundToDouble() ? 0 : 2,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h + safeBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Отклик на объявление',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              widget.order.routeLabel,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'Сумма заказа',
                    value: widget.order.priceLabel,
                  ),
                  SizedBox(height: 4.h),
                  _InfoRow(
                    label: 'Тип ТС',
                    value: widget.order.vehicleTypeLabel,
                  ),
                ],
              ),
            ),
            if (!_showAmountField)
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAmountField = true;
                        if (_amountController.text.isEmpty) {
                          final amount = widget.order.amountValue;
                          if (amount != null && amount > 0) {
                            _amountController.text = amount.toStringAsFixed(
                              amount == amount.roundToDouble() ? 0 : 2,
                            );
                          }
                        }
                      });
                    },
                    child: const Text(
                      'Предложить свою цену',
                      style: TextStyle(color: Color(0xFF1E88E5)),
                    ),
                  ),
                ],
              ),
            if (_showAmountField) ...[
              SizedBox(height: 10.h),
              Text(
                'Ваша цена за перевозку',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Например, 120 000',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            Text(
              'Сопроводительное письмо (опционально)',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _commentController,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Расскажите отправителю, когда сможете приехать',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child:
                    _isSubmitting
                        ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Отправить отклик'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    double? parsedAmount;
    if (_showAmountField) {
      parsedAmount = double.tryParse(
        _amountController.text.replaceAll(',', '.'),
      );
    } else {
      parsedAmount = widget.order.amountValue;
    }
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите корректную сумму отклика.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final repository = ref.read(orderRepositoryProvider);
    final comment = _commentController.text.trim();
    try {
      await repository.createDriverBid(
        orderId: widget.order.id,
        amount: parsedAmount,
        comment: comment.isEmpty ? null : comment,
      );
      ref.read(respondedOrdersProvider.notifier).markResponded(widget.order.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отправить отклик')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
