class Payment {
  final String id;
  final String dairyCode;
  final String farmerId;
  final String farmerName;
  final double amount;
  final DateTime date;
  final String paymentType; // e.g., "Cash", "Bank Transfer"
  final String notes;

  const Payment({
    required this.id,
    required this.dairyCode,
    required this.farmerId,
    required this.farmerName,
    required this.amount,
    required this.date,
    required this.paymentType,
    required this.notes,
  });
}
