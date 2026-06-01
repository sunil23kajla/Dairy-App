import '../core/constants.dart';

class Collection {
  final String id;
  final String dairyCode;
  final String farmerId;
  final String farmerName;
  final DateTime date;
  final Session session;
  final double liters;
  final double? fat;
  final double? snf;
  final double rate;
  final double totalAmount;
  final bool isEdited;

  const Collection({
    required this.id,
    required this.dairyCode,
    required this.farmerId,
    required this.farmerName,
    required this.date,
    required this.session,
    required this.liters,
    this.fat,
    this.snf,
    this.rate = 0.0,
    this.totalAmount = 0.0,
    this.isEdited = false,
  });

  bool get isPendingFat => fat == null || fat == 0.0;

  Collection copyWith({
    String? id,
    String? dairyCode,
    String? farmerId,
    String? farmerName,
    DateTime? date,
    Session? session,
    double? liters,
    double? fat,
    double? snf,
    double? rate,
    double? totalAmount,
    bool? isEdited,
  }) {
    return Collection(
      id: id ?? this.id,
      dairyCode: dairyCode ?? this.dairyCode,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      date: date ?? this.date,
      session: session ?? this.session,
      liters: liters ?? this.liters,
      fat: fat ?? this.fat,
      snf: snf ?? this.snf,
      rate: rate ?? this.rate,
      totalAmount: totalAmount ?? this.totalAmount,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
