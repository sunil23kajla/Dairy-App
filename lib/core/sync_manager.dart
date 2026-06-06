import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'database_helper.dart';
import 'constants.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._init();
  SyncManager._init();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl, // Base URL imported from constants
    connectTimeout: const Duration(seconds: 40),
    headers: {'Bypass-Tunnel-Reminder': 'true'}, // Required for localtunnel
  ));

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  String? _activeDairyCode;

  void initialize(String dairyCode) {
    _activeDairyCode = dairyCode;
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        syncData();
      }
    });
    // Trigger initial sync
    syncData();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> syncData() async {
    if (_isSyncing || _activeDairyCode == null) return;
    _isSyncing = true;

    try {
      final dbHelper = DatabaseHelper.instance;

      // 1. PUSH local unsynced data
      final unsyncedFarmers = await dbHelper.getUnsyncedRows('farmers');
      final unsyncedCollections = await dbHelper.getUnsyncedRows('collections');
      final unsyncedPayouts = await dbHelper.getUnsyncedRows('payouts');

      if (unsyncedFarmers.isNotEmpty || unsyncedCollections.isNotEmpty || unsyncedPayouts.isNotEmpty) {
        final response = await _dio.post('/sync/push', data: {
          'dairyCode': _activeDairyCode,
          'farmers': unsyncedFarmers,
          'collections': unsyncedCollections,
          'payouts': unsyncedPayouts,
        });

        if (response.statusCode == 200) {
          // Mark as synced locally
          for (var f in unsyncedFarmers) {
            await dbHelper.markAsSynced('farmers', 'id', f['id']);
          }
          for (var c in unsyncedCollections) {
            await dbHelper.markAsSynced('collections', 'localId', c['localId']);
          }
          for (var p in unsyncedPayouts) {
            await dbHelper.markAsSynced('payouts', 'localId', p['localId']);
          }
        }
      }

      // 2. PULL remote data updates
      final pullResponse = await _dio.get('/sync/pull', queryParameters: {'dairyCode': _activeDairyCode});
      if (pullResponse.statusCode == 200) {
        final data = pullResponse.data['data'];
        
        // Helper to clean MongoDB fields for SQLite
        void cleanFields(Map<String, dynamic> record) {
          record['is_synced'] = 1;
          if (record['updatedAt'] != null) {
            record['updated_at'] = record['updatedAt'];
          }
          record.remove('_id');
          record.remove('__v');
          record.remove('updatedAt');
          record.remove('createdAt');
        }

        // Update local DB with pulled data
        if (data['farmers'] != null) {
          for (var f in data['farmers']) {
            cleanFields(f);
            await dbHelper.insertOrUpdate('farmers', f);
          }
        }
        
        if (data['collections'] != null) {
          for (var c in data['collections']) {
            cleanFields(c);
            await dbHelper.insertOrUpdate('collections', c);
          }
        }

        if (data['payouts'] != null) {
          for (var p in data['payouts']) {
            cleanFields(p);
            await dbHelper.insertOrUpdate('payouts', p);
          }
        }
      }

    } catch (e) {
      print('Sync Error: \$e');
    } finally {
      _isSyncing = false;
    }
  }
  Future<void> deleteCollectionFromApi(String localId) async {
    try {
      await _dio.delete('/sync/collection/$localId');
    } catch (e) {
      print('Delete API Error: $e');
    }
  }

  Future<void> updateRateSettingsApi(String dairyCode, double fatFactor, double snfFactor) async {
    try {
      await _dio.post('/auth/dairy/$dairyCode/rate', data: {
        'fatFactor': fatFactor,
        'snfFactor': snfFactor,
      });
    } catch (e) {
      print('Rate API Error: $e');
    }
  }
}
