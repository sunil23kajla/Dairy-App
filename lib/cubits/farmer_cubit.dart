import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/farmer.dart';
import '../core/database_helper.dart';
import '../core/sync_manager.dart';

class FarmerState extends Equatable {
  final List<Farmer> farmers;
  final bool isLoading;

  const FarmerState({
    required this.farmers,
    this.isLoading = false,
  });

  @override
  List<Object> get props => [farmers, isLoading];

  FarmerState copyWith({
    List<Farmer>? farmers,
    bool? isLoading,
  }) {
    return FarmerState(
      farmers: farmers ?? this.farmers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FarmerCubit extends Cubit<FarmerState> {
  FarmerCubit() : super(const FarmerState(farmers: [], isLoading: true));

  Future<void> loadFarmers(String dairyCode) async {
    emit(state.copyWith(isLoading: true));
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'farmers',
      where: 'dairyCode = ?',
      whereArgs: [dairyCode],
    );

    final farmers = maps.map((map) => Farmer(
      id: map['id'],
      dairyCode: map['dairyCode'],
      name: map['name'],
      nickname: map['name'].split(' ')[0],
      mobile: map['mobile'],
      lastLiters: 0.0, // Last liters would normally be a join or computed
    )).toList();

    emit(FarmerState(farmers: farmers, isLoading: false));
  }

  Future<void> addFarmer(String name, String nickname, String mobile, String dairyCode) async {
    emit(state.copyWith(isLoading: true));
    
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    
    // Get max ID
    final result = await db.rawQuery('SELECT id FROM farmers WHERE dairyCode = ? ORDER BY CAST(id AS INTEGER) DESC LIMIT 1', [dairyCode]);
    final nextId = result.isEmpty ? '1' : ((int.tryParse(result.first['id'].toString()) ?? 0) + 1).toString();
        
    final newFarmer = {
      'id': nextId,
      'dairyCode': dairyCode,
      'name': name,
      'mobile': mobile,
      'is_synced': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await dbHelper.insertOrUpdate('farmers', newFarmer);
    
    // Trigger sync
    SyncManager.instance.syncData();
    
    // Reload UI
    await loadFarmers(dairyCode);
  }

  Future<void> editFarmer(String id, String dairyCode, String name, String nickname, String mobile) async {
    emit(state.copyWith(isLoading: true));
    
    final dbHelper = DatabaseHelper.instance;
    final updatedFarmer = {
      'id': id,
      'dairyCode': dairyCode,
      'name': name,
      'mobile': mobile,
      'is_synced': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await dbHelper.insertOrUpdate('farmers', updatedFarmer);
    SyncManager.instance.syncData();
    await loadFarmers(dairyCode);
  }

  void updateLastLiters(String id, String dairyCode, double liters) {
    final updatedList = state.farmers.map((farmer) {
      if (farmer.id == id && farmer.dairyCode == dairyCode) {
        return farmer.copyWith(lastLiters: liters);
      }
      return farmer;
    }).toList();
    emit(state.copyWith(farmers: updatedList));
  }

  Future<void> deleteFarmer(String id, String dairyCode) async {
    emit(state.copyWith(isLoading: true));
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    
    await db.delete(
      'farmers',
      where: 'id = ? AND dairyCode = ?',
      whereArgs: [id, dairyCode],
    );
    
    await loadFarmers(dairyCode);
  }
}
