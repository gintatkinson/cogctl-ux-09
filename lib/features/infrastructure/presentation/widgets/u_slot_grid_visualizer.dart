import 'package:flutter/material.dart';
import 'package:cogctl_ux/features/infrastructure/domain/equipment_rack.dart';

class USlotGridVisualizer extends StatelessWidget {
  final EquipmentRack rack;
  final bool isDark;

  const USlotGridVisualizer({
    super.key,
    required this.rack,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final int units = (rack.height / 44.45).round().clamp(1, 48);
    
    // Choose cabinet color based on class
    Color cabinetColor;
    String securityLabel;
    IconData lockIcon;
    switch (rack.rackClass) {
      case 'rack-secure-baseline':
        cabinetColor = Colors.green;
        securityLabel = 'SECURE BASELINE';
        lockIcon = Icons.lock_open;
        break;
      case 'rack-secure-medium':
        cabinetColor = Colors.orange;
        securityLabel = 'SECURE MEDIUM';
        lockIcon = Icons.lock;
        break;
      case 'rack-secure-high':
        cabinetColor = Colors.red;
        securityLabel = 'SECURE HIGH';
        lockIcon = Icons.gpp_bad; // Bio/high security
        break;
      default:
        cabinetColor = const Color(0xFF3367D6);
        securityLabel = 'STANDARD';
        lockIcon = Icons.lock_open;
    }

    final cardBg = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F3F4);
    final slotBg = isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE8EAED);

    final int totalPower = rack.containedChassis.fold<int>(0, (sum, c) => sum + c.powerConsumption);
    final double powerRatio = rack.maxAllocatedPower > 0 ? (totalPower / rack.maxAllocatedPower) : 0.0;
    final bool isOverpowered = totalPower > rack.maxAllocatedPower;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cabinetColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: cabinetColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(lockIcon, color: cabinetColor, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      securityLabel,
                      style: TextStyle(
                        color: cabinetColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                '${units}U CABINET',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 16),

          // Electricity indicators
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Power: $totalPower W / ${rack.maxAllocatedPower} W',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOverpowered ? Colors.red : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    Text(
                      'Voltage: ${rack.maxVoltage} V',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: powerRatio.clamp(0.0, 1.0),
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    color: isOverpowered ? Colors.red : Colors.green,
                    minHeight: 8,
                  ),
                ),
                if (isOverpowered) ...[
                  const SizedBox(height: 4),
                  const Text(
                    '⚠️ POWER CAPACITY EXCEEDED!',
                    style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),

          // Scrollable Rack representation
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFDCDCDC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: cabinetColor, width: 3),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                itemCount: units,
                itemBuilder: (context, index) {
                  final uIndex = units - index; // Numbered top to bottom
                  
                  final RackContainedChassis? chassis = rack.containedChassis
                      .where((c) => c.relativePosition == uIndex)
                      .firstOrNull;

                  final bool isFilled = chassis != null;
                  final Color moduleColor = isFilled 
                      ? Colors.teal.withValues(alpha: 0.2) 
                      : slotBg;
                  final String moduleLabel = isFilled 
                      ? '${chassis.neRef} / ${chassis.componentRef} (${chassis.powerConsumption} W)' 
                      : 'Slot U$uIndex: Empty';
                  final IconData? moduleIcon = isFilled ? Icons.dns : null;

                  return Container(
                    height: 24,
                    key: ValueKey('rack-slot-$uIndex'),
                    margin: const EdgeInsets.symmetric(vertical: 1.5),
                    decoration: BoxDecoration(
                      color: moduleColor,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isFilled ? cabinetColor.withValues(alpha: 0.7) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Slot Label
                        Container(
                          width: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black26,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Module details
                        if (moduleIcon != null) ...[
                          Icon(moduleIcon, size: 12, color: cabinetColor),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            moduleLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isFilled ? FontWeight.bold : FontWeight.normal,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
