import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_service.dart';
import 'database_service.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final ConnectivityService _connectivityService = ConnectivityService();
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService._init();

  // Start automatic background sync
  void startAutoSync({Duration interval = const Duration(minutes: 15)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncData());
    
    // Also listen to connectivity changes
    _connectivityService.connectivityStream.listen((result) {
      if (result != ConnectivityResult.none && !_isSyncing) {
        syncData();
      }
    });
  }

  // Stop automatic sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Manual sync
  Future<bool> syncData() async {
    if (_isSyncing) return false;

    final isOnline = await _connectivityService.isConnected();
    if (!isOnline) {
      debugPrint('SyncService: Device is offline, skipping sync');
      return false;
    }

    _isSyncing = true;
    debugPrint('SyncService: Starting data sync...');

    try {
      // Fetch all timetables from server
      final response = await ApiService.getBusTimeTable();
      
      if (response['success'] == true && response['data'] != null) {
        // Save to local database
        await DatabaseService.instance.saveBusTimetables(
          List<Map<String, dynamic>>.from(response['data']),
        );
        
        debugPrint('SyncService: Sync completed successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('SyncService: Sync failed - ${e.toString()}');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    return await DatabaseService.instance.getLastSync();
  }
}