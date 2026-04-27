import 'package:flutter/material.dart';
import '../../scanner/domain/port_model.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:math';

class NetworkTreeWidget extends StatelessWidget {
  final String targetIp;
  final List<PortModel> ports;
  final Function(PortModel) onPortSelected;
  final PortModel? selectedPort;

  const NetworkTreeWidget({
    super.key,
    required this.targetIp,
    required this.ports,
    required this.onPortSelected,
    this.selectedPort,
  });

  @override
  Widget build(BuildContext context) {
    if (ports.isEmpty) {
      return const Center(
        child: Text(
          'Scan complete, but no open ports found.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(500),
      minScale: 0.1,
      maxScale: 3.0,
      child: SizedBox(
        width: 1000,
        height: 1000,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background lines (drawn with CustomPainter)
            Positioned.fill(
              child: CustomPaint(
                painter: _NetworkLinesPainter(targetIp: targetIp, ports: ports),
              ),
            ),
            
            // Kali Node
            _buildPositionedNode(
              center: const Offset(500, 100),
              text: 'Kali (You)',
              color: AppColors.primary,
              radius: 50,
            ),
            
            // Target Node
            _buildPositionedNode(
              center: const Offset(500, 300),
              text: targetIp,
              color: AppColors.surfaceHighlight,
              radius: 50,
            ),
            
            // Port Nodes
            ..._buildPortNodes(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPortNodes() {
    final int count = ports.length;
    const double radius = 300; // Spread radius for ports
    final double angleStep = pi / (count + 1); 
    final targetCenter = const Offset(500, 300);

    return List.generate(count, (i) {
      final port = ports[i];
      final angle = angleStep * (i + 1);
      final portX = targetCenter.dx + radius * cos(angle);
      final portY = targetCenter.dy + radius * sin(angle);
      
      final isSelected = selectedPort?.port == port.port;

      return _buildPositionedNode(
        center: Offset(portX, portY),
        text: '${port.port}\n${port.serviceName}',
        color: _getRiskColor(port.riskLevel),
        radius: isSelected ? 45 : 40,
        isInteractive: true,
        isSelected: isSelected,
        onTap: () => onPortSelected(port),
      );
    });
  }

  Widget _buildPositionedNode({
    required Offset center,
    required String text,
    required Color color,
    required double radius,
    bool isInteractive = false,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Positioned(
      left: center.dx - radius,
      top: center.dy - radius,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                color: isSelected ? Colors.white : color,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isSelected ? 0.6 : 0.2),
                  blurRadius: isSelected ? 25 : 15,
                  spreadRadius: isSelected ? 5 : 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.critical: return AppColors.critical;
      case RiskLevel.high: return AppColors.high;
      case RiskLevel.medium: return AppColors.medium;
      case RiskLevel.low: return AppColors.low;
    }
  }
}

class _NetworkLinesPainter extends CustomPainter {
  final String targetIp;
  final List<PortModel> ports;

  _NetworkLinesPainter({required this.targetIp, required this.ports});

  @override
  void paint(Canvas canvas, Size size) {
    final rootNode = const Offset(500, 100);
    final targetNode = const Offset(500, 300);

    final linePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(rootNode, targetNode, linePaint);

    if (ports.isNotEmpty) {
      final int count = ports.length;
      const double radius = 300; 
      final double angleStep = pi / (count + 1); 

      for (int i = 0; i < count; i++) {
        final port = ports[i];
        final angle = angleStep * (i + 1);
        final portNode = Offset(
          targetNode.dx + radius * cos(angle),
          targetNode.dy + radius * sin(angle),
        );

        final portLinePaint = Paint()
          ..color = _getRiskColor(port.riskLevel).withOpacity(0.5)
          ..strokeWidth = 1.5;
        canvas.drawLine(targetNode, portNode, portLinePaint);
      }
    }
  }

  Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.critical: return AppColors.critical;
      case RiskLevel.high: return AppColors.high;
      case RiskLevel.medium: return AppColors.medium;
      case RiskLevel.low: return AppColors.low;
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkLinesPainter oldDelegate) {
    return oldDelegate.ports != ports || oldDelegate.targetIp != targetIp;
  }
}
