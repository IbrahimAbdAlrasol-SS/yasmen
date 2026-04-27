import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/port_model.dart';
import '../data/nmap_service.dart';

// Provides the NmapService instance
final nmapServiceProvider = Provider<NmapService>((ref) {
  return NmapService();
});

// Defines the possible states of our scanner
class ScannerState {
  final bool isScanning;
  final List<PortModel> ports;
  final String? error;
  final PortModel? selectedPort;

  const ScannerState({
    this.isScanning = false,
    this.ports = const [],
    this.error,
    this.selectedPort,
  });

  ScannerState copyWith({
    bool? isScanning,
    List<PortModel>? ports,
    String? error,
    bool clearError = false,
    PortModel? selectedPort,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      ports: ports ?? this.ports,
      error: clearError ? null : (error ?? this.error),
      selectedPort: selectedPort ?? this.selectedPort,
    );
  }
}

// The Notifier that manages the state
class ScannerNotifier extends StateNotifier<ScannerState> {
  final NmapService _nmapService;

  ScannerNotifier(this._nmapService) : super(const ScannerState());

  Future<void> startScan(String targetIp) async {
    // Basic IP validation
    if (targetIp.isEmpty) {
      state = state.copyWith(error: 'Target IP cannot be empty.');
      return;
    }

    // Set state to scanning, clear previous errors and results
    state = state.copyWith(isScanning: true, clearError: true, ports: []);

    try {
      final results = await _nmapService.runScan(targetIp);
      state = state.copyWith(isScanning: false, ports: results);
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
    }
  }

  void selectPort(PortModel port) {
    state = state.copyWith(selectedPort: port);
  }

  void loadMockData() {
    state = state.copyWith(
      isScanning: false,
      clearError: true,
      ports: [
        PortModel(port: 21, state: 'open', serviceName: 'ftp', serviceVersion: 'vsftpd 2.3.4', riskLevel: RiskLevel.critical),
        PortModel(port: 22, state: 'open', serviceName: 'ssh', serviceVersion: 'OpenSSH 4.7p1', riskLevel: RiskLevel.medium),
        PortModel(port: 23, state: 'open', serviceName: 'telnet', serviceVersion: 'Linux telnetd', riskLevel: RiskLevel.high),
        PortModel(port: 80, state: 'open', serviceName: 'http', serviceVersion: 'Apache httpd 2.2.8', riskLevel: RiskLevel.medium),
        PortModel(port: 139, state: 'open', serviceName: 'netbios-ssn', serviceVersion: 'Samba smbd 3.X', riskLevel: RiskLevel.critical),
        PortModel(port: 3306, state: 'open', serviceName: 'mysql', serviceVersion: 'MySQL 5.0.51a', riskLevel: RiskLevel.high),
        PortModel(port: 5432, state: 'open', serviceName: 'postgresql', serviceVersion: 'PostgreSQL DB 8.3.0', riskLevel: RiskLevel.high),
      ],
    );
  }
}

// The provider to expose the ScannerNotifier to the UI
final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final nmapService = ref.watch(nmapServiceProvider);
  return ScannerNotifier(nmapService);
});
