import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:fura24.kz/features/client/domain/models/history_status.dart';

class HistoryFilter extends Equatable {
  const HistoryFilter({
    this.status = HistoryStatus.all,
    this.dateRange,
    this.searchQuery = '',
  });

  final HistoryStatus status;
  final DateTimeRange? dateRange;
  final String searchQuery;

  HistoryFilter copyWith({
    HistoryStatus? status,
    DateTimeRange? dateRange,
    String? searchQuery,
    bool clearDateRange = false,
  }) {
    return HistoryFilter(
      status: status ?? this.status,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [status, dateRange, searchQuery];
}
