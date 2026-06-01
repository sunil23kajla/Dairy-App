import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../core/constants.dart';
import '../models/collection.dart';
import '../models/payment.dart';
import '../core/database_helper.dart';
import '../core/sync_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionState extends Equatable {
  final List<Collection> collections;
  final List<Payment> payments;
  final String? warningMessage;
  final double fatFactor;
  final double snfFactor;
  final bool isLoading;

  const CollectionState({
    required this.collections,
    required this.payments,
    this.warningMessage,
    this.fatFactor = 9.0,
    this.snfFactor = 9.0,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [collections, payments, warningMessage, fatFactor, snfFactor, isLoading];

  CollectionState copyWith({
    List<Collection>? collections,
    List<Payment>? payments,
    String? warningMessage,
    double? fatFactor,
    double? snfFactor,
    bool? isLoading,
  }) {
    return CollectionState(
      collections: collections ?? this.collections,
      payments: payments ?? this.payments,
      warningMessage: warningMessage,
      fatFactor: fatFactor ?? this.fatFactor,
      snfFactor: snfFactor ?? this.snfFactor,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CollectionCubit extends Cubit<CollectionState> {
  CollectionCubit()
      : super(const CollectionState(
          collections: [],
          payments: [],
          isLoading: true,
        ));

  Future<void> loadCollections(String dairyCode) async {
    emit(state.copyWith(isLoading: true));
    
    final prefs = await SharedPreferences.getInstance();
    final fatFactor = prefs.getDouble('fatFactor_${dairyCode}') ?? 9.0;
    final snfFactor = prefs.getDouble('snfFactor_${dairyCode}') ?? 9.0;

    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    
    // Load Collections
    final List<Map<String, dynamic>> colMaps = await db.query(
      'collections',
      where: 'dairyCode = ?',
      whereArgs: [dairyCode],
    );

    final collections = colMaps.map((map) => Collection(
      id: map['localId'],
      dairyCode: map['dairyCode'],
      farmerId: map['farmerId'],
      farmerName: map['farmerName'],
      date: DateTime.parse(map['date']),
      session: map['session'] == 'morning' ? Session.morning : Session.evening,
      liters: map['liters'],
      fat: map['fat'],
      snf: map['snf'],
      rate: map['rate'] ?? 0.0,
      totalAmount: map['totalAmount'] ?? 0.0,
    )).toList();

    // Load Payouts
    final List<Map<String, dynamic>> payMaps = await db.query(
      'payouts',
      where: 'dairyCode = ?',
      whereArgs: [dairyCode],
    );

    final payments = payMaps.map((map) => Payment(
      id: map['localId'],
      dairyCode: map['dairyCode'],
      farmerId: map['farmerId'],
      farmerName: map['farmerName'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      paymentType: map['paymentType'],
      notes: map['notes'],
    )).toList();

    emit(state.copyWith(
      collections: collections,
      payments: payments,
      fatFactor: fatFactor,
      snfFactor: snfFactor,
      isLoading: false,
    ));
  }

  void clearWarning() {
    emit(state.copyWith(warningMessage: null));
  }

  // Record a milk entry
  Future<bool> addMilkEntry(String farmerId, String farmerName, double liters, Session session, String dairyCode) async {
    final today = DateTime.now();
    final isDuplicate = state.collections.any((c) =>
        c.dairyCode == dairyCode &&
        c.farmerId == farmerId &&
        c.session == session &&
        c.date.year == today.year &&
        c.date.month == today.month &&
        c.date.day == today.day);

    if (isDuplicate) {
      emit(state.copyWith(warningMessage: 'Farmer already entered in this session!'));
      return false; 
    }

    final newCollection = {
      'localId': 'c_${DateTime.now().millisecondsSinceEpoch}',
      'dairyCode': dairyCode,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'date': DateTime.now().toIso8601String(),
      'session': session == Session.morning ? 'morning' : 'evening',
      'liters': liters,
      'fat': null,
      'snf': null,
      'rate': 0.0,
      'totalAmount': 0.0,
      'isPendingFat': 1,
      'is_synced': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await DatabaseHelper.instance.insertOrUpdate('collections', newCollection);
    SyncManager.instance.syncData();
    await loadCollections(dairyCode);
    return true;
  }

  // Resolve duplicate entries
  Future<void> resolveDuplicateCollection({
    required String farmerId,
    required Session session,
    required double liters,
    required bool addToExisting,
    required String dairyCode,
  }) async {
    final today = DateTime.now();
    final match = state.collections.firstWhere((c) => 
        c.dairyCode == dairyCode &&
        c.farmerId == farmerId &&
        c.session == session &&
        c.date.year == today.year &&
        c.date.month == today.month &&
        c.date.day == today.day);
      
    final newLiters = addToExisting ? match.liters + liters : liters;
    double newRate = match.rate;
    double newTotalAmount = match.totalAmount;
    
    if (!match.isPendingFat) {
      final fat = match.fat ?? 0.0;
      final snf = match.snf ?? 0.0;
      newRate = AppConstants.calculateRate(fat, snf, fatFactor: state.fatFactor, baseSnf: state.snfFactor);
      newTotalAmount = double.parse((newLiters * newRate).toStringAsFixed(2));
    }

    final updatedCollection = {
      'localId': match.id,
      'dairyCode': dairyCode,
      'farmerId': farmerId,
      'farmerName': match.farmerName,
      'date': match.date.toIso8601String(),
      'session': match.session == Session.morning ? 'morning' : 'evening',
      'liters': newLiters,
      'fat': match.fat,
      'snf': match.snf,
      'rate': newRate,
      'totalAmount': newTotalAmount,
      'isPendingFat': match.isPendingFat ? 1 : 0,
      'is_synced': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await DatabaseHelper.instance.insertOrUpdate('collections', updatedCollection);
    SyncManager.instance.syncData();
    await loadCollections(dairyCode);
  }

  // Update FAT & SNF
  Future<void> updateFatSnf(String id, double fat, double snf, String dairyCode) async {
    final rate = AppConstants.calculateRate(fat, snf, fatFactor: state.fatFactor, baseSnf: state.snfFactor);
    final match = state.collections.firstWhere((c) => c.id == id);
    
    final updatedCollection = {
      'localId': id,
      'dairyCode': match.dairyCode,
      'farmerId': match.farmerId,
      'farmerName': match.farmerName,
      'date': match.date.toIso8601String(),
      'session': match.session == Session.morning ? 'morning' : 'evening',
      'liters': match.liters,
      'fat': fat,
      'snf': snf,
      'rate': rate,
      'totalAmount': double.parse((match.liters * rate).toStringAsFixed(2)),
      'isPendingFat': 0,
      'is_synced': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await DatabaseHelper.instance.insertOrUpdate('collections', updatedCollection);
    SyncManager.instance.syncData();
    await loadCollections(dairyCode);
  }

  Future<void> updateRateFactors(double fatFactor, double snfFactor, String dairyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fatFactor_${dairyCode}', fatFactor);
    await prefs.setDouble('snfFactor_${dairyCode}', snfFactor);
    emit(state.copyWith(fatFactor: fatFactor, snfFactor: snfFactor));
    SyncManager.instance.updateRateSettingsApi(dairyCode, fatFactor, snfFactor);
  }

  Future<void> deleteCollection(String id, String dairyCode) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('collections', where: 'localId = ?', whereArgs: [id]);
    await SyncManager.instance.deleteCollectionFromApi(id);
    await loadCollections(dairyCode);
  }

  Future<void> addPayment(String farmerId, String farmerName, double amount, String paymentType, String notes, String dairyCode) async {
    final newPayment = {
      'localId': 'p_${DateTime.now().millisecondsSinceEpoch}',
      'dairyCode': dairyCode,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'paymentType': paymentType,
      'notes': notes.isEmpty ? 'Paid' : notes,
      'is_synced': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await DatabaseHelper.instance.insertOrUpdate('payouts', newPayment);
    SyncManager.instance.syncData();
    await loadCollections(dairyCode);
  }

  // Summary Metrics calculations (filtered by active dairyCode)
  double getTodayTotalLiters(String dairyCode) {
    final today = DateTime.now();
    return state.collections
        .where((c) =>
            c.dairyCode == dairyCode &&
            c.date.year == today.year &&
            c.date.month == today.month &&
            c.date.day == today.day)
        .fold(0.0, (sum, c) => sum + c.liters);
  }

  double getTodayTotalAmount(String dairyCode) {
    final today = DateTime.now();
    return state.collections
        .where((c) =>
            c.dairyCode == dairyCode &&
            c.date.year == today.year &&
            c.date.month == today.month &&
            c.date.day == today.day)
        .fold(0.0, (sum, c) => sum + c.totalAmount);
  }

  int getTodayPendingFatCount(String dairyCode) {
    final today = DateTime.now();
    return state.collections
        .where((c) =>
            c.dairyCode == dairyCode &&
            c.date.year == today.year &&
            c.date.month == today.month &&
            c.date.day == today.day &&
            c.isPendingFat)
        .length;
  }

  double getFarmerBalance(String farmerId, String dairyCode) {
    final earned = state.collections
        .where((c) => c.dairyCode == dairyCode && c.farmerId == farmerId && !c.isPendingFat)
        .fold(0.0, (sum, c) => sum + c.totalAmount);
    
    final paid = state.payments
        .where((p) => p.dairyCode == dairyCode && p.farmerId == farmerId)
        .fold(0.0, (sum, p) => sum + p.amount);

    return double.parse((earned - paid).toStringAsFixed(2));
  }
}
