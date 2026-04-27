enum RiskLevel { low, medium, high, critical }

class PortModel {
  final int port;
  final String state; // open, closed, filtered
  final String serviceName;
  final String serviceVersion;
  final RiskLevel riskLevel;

  PortModel({
    required this.port,
    required this.state,
    required this.serviceName,
    required this.serviceVersion,
    required this.riskLevel,
  });

  factory PortModel.fromXml(int portId, String state, String name, String version) {
    return PortModel(
      port: portId,
      state: state,
      serviceName: name,
      serviceVersion: version,
      riskLevel: _calculateRisk(name, version),
    );
  }

  static RiskLevel _calculateRisk(String serviceName, String version) {
    final lowerName = serviceName.toLowerCase();
    // Basic heuristic for Metasploitable2 services
    if (lowerName.contains('ftp') && version.contains('2.3.4')) return RiskLevel.critical; // vsftpd backdoor
    if (lowerName.contains('smb') || lowerName.contains('netbios')) return RiskLevel.critical;
    if (lowerName.contains('ssh')) return RiskLevel.medium;
    if (lowerName.contains('telnet')) return RiskLevel.high;
    if (lowerName.contains('http')) return RiskLevel.medium;
    if (lowerName.contains('mysql') || lowerName.contains('postgresql')) return RiskLevel.high;
    
    return RiskLevel.low;
  }

  @override
  String toString() {
    return 'Port $port ($state): $serviceName $serviceVersion [${riskLevel.name.toUpperCase()}]';
  }
}
