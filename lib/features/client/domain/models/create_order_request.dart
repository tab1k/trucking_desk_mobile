import 'dart:io';

/// DTO с типизированными полями для создания заявки на перевозку.
class CreateOrderRequest {
  const CreateOrderRequest({
    required this.departurePointId,
    required this.destinationPointId,
    required this.cargoName,
    required this.vehicleType,
    required this.loadingType,
    required this.weightTons,
    required this.amount,
    required this.paymentType,
    required this.currency,
    required this.photos,
    this.cargoTypeId,
    this.volumeCubicMeters,
    this.lengthMeters,
    this.widthMeters,
    this.heightMeters,
    this.description,
    this.transportationDate,
    this.transportationTermDays,
    this.distanceKm,
    this.estimatedTimeHours,
    this.totalCost,
  });

  final int departurePointId;
  final int destinationPointId;
  final String cargoName;
  final String vehicleType;
  final String loadingType;
  final double weightTons;
  final double? volumeCubicMeters;
  final double? lengthMeters;
  final double? widthMeters;
  final double? heightMeters;
  final String? description;
  final DateTime? transportationDate;
  final int? transportationTermDays;
  final double? distanceKm;
  final double? estimatedTimeHours;
  final double? totalCost;
  final double amount;
  final String paymentType;
  final String currency;
  final int? cargoTypeId;
  final List<File> photos;
}
