import 'dart:io';
import 'dart:isolate';
import 'package:xml/xml.dart';
import '../domain/port_model.dart';

class NmapService {
  /// Runs Nmap and returns a list of parsed PortModels.
  /// Throws an exception if it fails.
  Future<List<PortModel>> runScan(String targetIp) async {
    try {
      // Run nmap with version detection (-sV), fast timing (-T4), and output XML to stdout (-oX -)
      // Note: On Kali Linux, standard user might need sudo, but we assume the app runs as root or uses pkexec/sudo
      final result = await Process.run(
        'nmap',
        ['-sV', '-T4', '-oX', '-', targetIp],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        throw Exception('Nmap scan failed: ${result.stderr}');
      }

      final String xmlOutput = result.stdout as String;

      // Parse the heavy XML on a background Isolate to prevent UI lag (Zero Lag approach)
      final parsedPorts = await Isolate.run(() => _parseNmapXml(xmlOutput));
      
      return parsedPorts;
    } catch (e) {
      throw Exception('Failed to run Nmap: $e');
    }
  }

  /// This function runs entirely on a background thread
  static List<PortModel> _parseNmapXml(String xmlString) {
    final List<PortModel> portsList = [];
    
    if (xmlString.isEmpty) return portsList;

    try {
      final document = XmlDocument.parse(xmlString);
      final hosts = document.findAllElements('host');

      for (var host in hosts) {
        final ports = host.findAllElements('port');
        for (var port in ports) {
          final portId = int.tryParse(port.getAttribute('portid') ?? '0') ?? 0;
          
          final stateElement = port.findElements('state').firstOrNull;
          final state = stateElement?.getAttribute('state') ?? 'unknown';

          final serviceElement = port.findElements('service').firstOrNull;
          final serviceName = serviceElement?.getAttribute('name') ?? 'unknown';
          final product = serviceElement?.getAttribute('product') ?? '';
          final version = serviceElement?.getAttribute('version') ?? '';
          
          final fullVersion = '$product $version'.trim();

          portsList.add(
            PortModel.fromXml(portId, state, serviceName, fullVersion),
          );
        }
      }
    } catch (e) {
      // In case XML is malformed
      throw Exception('Error parsing XML: $e');
    }

    return portsList;
  }
}
