import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../core/network/network_info.dart';
import '../../core/di/injector.dart'; // For sl (service locator)

class NetworkStatusBanner extends StatefulWidget {
  const NetworkStatusBanner({super.key});

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  bool? _isConnected; // Nullable to represent "undetermined" initially
  final NetworkInfo _networkInfo = sl<NetworkInfo>();

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();

    _networkInfo.onConnectivityChanged.listen((ConnectivityResult result) {
      // The stream now directly gives a single ConnectivityResult
      final currentlyConnected = (result != ConnectivityResult.none);

      if (mounted && _isConnected != currentlyConnected) {
        setState(() {
          _isConnected = currentlyConnected;
        });

        // Show snackbar on change, only if the screen is active
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          if (!currentlyConnected) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content:
                      Text('You are offline. Some features may be limited.'),
                  backgroundColor: Colors.orangeAccent,
                  duration: Duration(seconds: 3),
                ),
              );
          } else {
            // Only show "Back online" if it was previously false
             if (_isConnected == true) { // Check _isConnected state directly after update
               ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Back online!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
             }
          }
        }
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final connected = await _networkInfo.isConnected;
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
      // Show initial offline snackbar if applicable and screen is active
      if (!connected && (ModalRoute.of(context)?.isCurrent ?? false)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('You are offline. Some features may be limited.'),
              backgroundColor: Colors.orangeAccent,
              duration: Duration(seconds: 3),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected == null || _isConnected == true) {
      return const SizedBox.shrink(); // Don't show if connected or undetermined
    }

    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'You are currently offline',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}