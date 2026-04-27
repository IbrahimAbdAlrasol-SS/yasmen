import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../scanner/domain/port_model.dart';
import '../../scanner/presentation/scanner_provider.dart';
import '../../visualizer/presentation/network_tree_widget.dart';
import '../../vulnerabilities/data/vulnerability_database.dart';
import 'package:flutter/services.dart';
import '../../visualizer/presentation/network_tree_widget.dart';

class NetworkDashboardScreen extends ConsumerStatefulWidget {
  const NetworkDashboardScreen({super.key});

  @override
  ConsumerState<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends ConsumerState<NetworkDashboardScreen> {
  final TextEditingController _ipController = TextEditingController(text: '127.0.0.1'); // Default for local test

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NetHawk Dashboard'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const HugeIcon(
          icon: HugeIcons.strokeRoundedShield01,
          color: AppColors.primary,
        ),
      ),
      body: Row(
        children: [
          // Left Panel: Scanner Controls
          Container(
            width: 300,
            color: AppColors.surface,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Target Setup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Gap(16),
                TextFormField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'Target IP (e.g. 192.168.1.5)',
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedTarget01,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: scannerState.isScanning
                        ? null
                        : () {
                            ref.read(scannerProvider.notifier).startScan(_ipController.text);
                          },
                    child: scannerState.isScanning
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Start Nmap Scan'),
                  ),
                ),
                const Gap(10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: scannerState.isScanning
                        ? null
                        : () {
                            ref.read(scannerProvider.notifier).loadMockData();
                          },
                    child: const Text('Test UI (Mock Data)', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const Gap(16),
                if (scannerState.error != null)
                  Text(
                    scannerState.error!,
                    style: const TextStyle(color: AppColors.critical),
                  ),
              ],
            ),
          ),
          
          // Center: Visual Tree
          Expanded(
            child: Container(
              color: AppColors.background,
              child: scannerState.isScanning
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : scannerState.ports.isEmpty
                      ? const Center(child: Text('No ports scanned yet or target is down.', style: TextStyle(color: AppColors.textSecondary)))
                      : NetworkTreeWidget(
                          targetIp: _ipController.text,
                          ports: scannerState.ports,
                          selectedPort: scannerState.selectedPort,
                          onPortSelected: (port) {
                            ref.read(scannerProvider.notifier).selectPort(port);
                          },
                        ),
            ),
          ),
          
          // Right Panel: Vulnerabilities
          Container(
            width: 380,
            color: AppColors.surface,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vulnerabilities & Exploits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Gap(16),
                if (scannerState.selectedPort == null)
                  const Text(
                    'Select a node to view CVEs and Metasploit modules.', 
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  Expanded(
                    child: _buildVulnerabilityPanel(scannerState.selectedPort!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVulnerabilityPanel(dynamic port) {
    final vulns = VulnerabilityDatabase.getVulnerabilities(port.serviceName, port.serviceVersion);

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Port: ${port.port}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Service: ${port.serviceName}'),
              Text('Version: ${port.serviceVersion}'),
            ],
          ),
        ),
        const Gap(16),
        ...vulns.map((v) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: port.riskLevel == RiskLevel.critical ? AppColors.critical : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Gap(4),
              Text('CVE: ${v.cve}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Gap(8),
              Text(v.description, style: const TextStyle(fontSize: 13)),
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        v.metasploitModule,
                        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: v.metasploitModule));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Module copied to clipboard!'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'critical': return AppColors.critical;
      case 'high': return AppColors.high;
      case 'medium': return AppColors.medium;
      case 'low': return AppColors.low;
      default: return AppColors.low;
    }
  }
}
