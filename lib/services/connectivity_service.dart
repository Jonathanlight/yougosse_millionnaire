import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service de detection de la connectivite reseau
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _isInitialized = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isInitialized => _isInitialized;

  /// Initialiser le service et ecouter les changements
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Verifier l'etat actuel
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);

    // Ecouter les changements
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    _isInitialized = true;
    debugPrint('[ConnectivityService] Initialise - Online: $_isOnline');
  }

  /// Mettre a jour le statut de connexion
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Verifier si au moins une connexion est disponible
    _isOnline = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    if (wasOnline != _isOnline) {
      debugPrint('[ConnectivityService] Statut change: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      notifyListeners();
    }
  }

  /// Verifier manuellement la connexion
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
    return _isOnline;
  }

  /// Attendre que la connexion soit disponible (avec timeout)
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    if (_isOnline) return true;

    final completer = Completer<bool>();
    Timer? timer;

    void listener() {
      if (_isOnline && !completer.isCompleted) {
        timer?.cancel();
        completer.complete(true);
      }
    }

    addListener(listener);

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        removeListener(listener);
        completer.complete(false);
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Instance globale du service de connectivite
final connectivityService = ConnectivityService();
