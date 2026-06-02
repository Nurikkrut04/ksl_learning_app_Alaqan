import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();
  
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  
  ConnectivityProvider() {
    _initConnectivity();
    _listenToConnectivityChanges();
  }
  
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }
  
  void _listenToConnectivityChanges() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }
  
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    // Если список пустой или содержит только none — офлайн
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (wasOnline != _isOnline) {
      notifyListeners();
      
      if (_isOnline) {
        debugPrint('Connection restored');
      } else {
        debugPrint('Connection lost');
      }
    }
  }
  
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking connection: $e');
      return false;
    }
  }
}
