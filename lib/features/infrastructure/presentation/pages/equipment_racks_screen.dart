import 'package:flutter/material.dart';
import 'package:cogctl_ux/utils/theme_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/core/utils/format_error.dart';
import 'package:cogctl_ux/features/infrastructure/domain/equipment_rack.dart';
import 'package:cogctl_ux/features/infrastructure/domain/inventory_location.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_equipment_rack_repository.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_inventory_location_repository.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_network_inventory_repository.dart';
import 'package:cogctl_ux/features/infrastructure/presentation/cubit/equipment_rack_cubit.dart';
import 'package:cogctl_ux/features/infrastructure/presentation/cubit/equipment_rack_state.dart';
import 'package:cogctl_ux/features/infrastructure/presentation/widgets/u_slot_grid_visualizer.dart';

class EquipmentRacksScreen extends StatelessWidget {
  const EquipmentRacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EquipmentRackCubit(
        sl<IEquipmentRackRepository>(),
        sl<IInventoryLocationRepository>(),
      ),
      child: const _EquipmentRacksView(),
    );
  }
}

class _EquipmentRacksView extends StatefulWidget {
  const _EquipmentRacksView();

  @override
  State<_EquipmentRacksView> createState() => _EquipmentRacksViewState();
}

class _EquipmentRacksViewState extends State<_EquipmentRacksView> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _timestampController = TextEditingController();
  final _validUntilController = TextEditingController();
  final _rowController = TextEditingController();
  final _colController = TextEditingController();
  final _maxVoltageController = TextEditingController(text: '240');
  final _maxAllocatedPowerController = TextEditingController(text: '6000');

  final _chassisUController = TextEditingController();
  final _chassisPowerController = TextEditingController();

  String? _selectedRackClass = 'rack-standard';
  String? _rackFormLocationId;
  String? _selectedPlacementLocationId;

  List<RackContainedChassis> _editingRackContainedChassis = [];
  String? _chassisNeRef;
  String? _chassisComponentRef;
  String? _chassisError;

  @override
  void dispose() {
    _idController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _timestampController.dispose();
    _validUntilController.dispose();
    _rowController.dispose();
    _colController.dispose();
    _maxVoltageController.dispose();
    _maxAllocatedPowerController.dispose();
    _chassisUController.dispose();
    _chassisPowerController.dispose();
    super.dispose();
  }

  void _populateForm(EquipmentRack rack) {
    _idController.text = rack.id;
    _selectedRackClass = rack.rackClass;
    _heightController.text = rack.height.toString();
    _widthController.text = rack.width.toString();
    _depthController.text = rack.depth.toString();
    _timestampController.text = rack.timestamp.toIso8601String();
    _validUntilController.text = rack.validUntil.toIso8601String();
    if (rack.rackLocation != null) {
      _rackFormLocationId = rack.rackLocation!.locationRef;
      _rowController.text = rack.rackLocation!.rowNumber?.toString() ?? '';
      _colController.text = rack.rackLocation!.columnNumber?.toString() ?? '';
    } else {
      _rackFormLocationId = null;
      _rowController.clear();
      _colController.clear();
    }
    _maxVoltageController.text = rack.maxVoltage.toString();
    _maxAllocatedPowerController.text = rack.maxAllocatedPower.toString();
    _editingRackContainedChassis = List<RackContainedChassis>.from(rack.containedChassis);
  }

  void _clearForm() {
    _idController.clear();
    _heightController.clear();
    _widthController.clear();
    _depthController.clear();
    _timestampController.clear();
    _validUntilController.clear();
    _rowController.clear();
    _colController.clear();
    _maxVoltageController.text = '240';
    _maxAllocatedPowerController.text = '6000';
    _editingRackContainedChassis = [];
    _selectedRackClass = 'rack-standard';
    _rackFormLocationId = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Load locations for placement
    final locations = sl<IInventoryLocationRepository>().getLocations();
    if (_selectedPlacementLocationId == null && locations.isNotEmpty) {
      _selectedPlacementLocationId = locations.first.id;
    }

    return BlocConsumer<EquipmentRackCubit, EquipmentRackState>(
      listener: (context, state) {
        if (state.generalError == null && state.status == EquipmentRackStatus.success) {
          // Success
        }
      },
      builder: (context, state) {
        final content = isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  _buildSummary(theme, state.racks),
                  const SizedBox(height: 24),
                  _buildFacilityFloorPlanCard(theme, state.racks, locations),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: SingleChildScrollView(child: _buildFormCard(theme, state, locations))),
                        const SizedBox(width: 24),
                        Expanded(flex: 6, child: _buildListPane(theme, state)),
                      ],
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 16),
                    _buildSummary(theme, state.racks),
                    const SizedBox(height: 24),
                    _buildFacilityFloorPlanCard(theme, state.racks, locations),
                    const SizedBox(height: 24),
                    _buildFormCard(theme, state, locations),
                    const SizedBox(height: 24),
                    _buildListPane(theme, state),
                  ],
                ),
              );

        return content;
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipment Racks & Bounds',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Physical Dimensions, Identityref Security Classification & Temporal Bounds Registry',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(ThemeData theme, List<EquipmentRack> racks) {
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    final total = racks.length;
    final standard = racks.where((r) => r.rackClass == 'rack-standard').length;
    final secure = total - standard;
    
    double avgHeight = 0;
    double avgWidth = 0;
    double avgDepth = 0;
    if (total > 0) {
      avgHeight = racks.map((r) => r.height).reduce((a, b) => a + b) / total;
      avgWidth = racks.map((r) => r.width).reduce((a, b) => a + b) / total;
      avgDepth = racks.map((r) => r.depth).reduce((a, b) => a + b) / total;
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL RACKS', '$total', Icons.grid_view, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'STANDARD GENERAL', '$standard', Icons.check_circle_outline, Colors.cyan),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'SECURED CABINETS', '$secure', Icons.security, Colors.redAccent),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'AVG HEIGHT (mm)', avgHeight.toStringAsFixed(0), Icons.height, Colors.amber),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'AVG WIDTH/DEPTH', '${avgWidth.toStringAsFixed(0)} / ${avgDepth.toStringAsFixed(0)}', Icons.settings_overscan, Colors.teal),
      ],
    );
  }

  Widget _buildMiniStatusCard(
    ThemeData theme,
    Color bg,
    BorderSide border,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border.color, width: border.width),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.15),
            radius: 18,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityFloorPlanCard(ThemeData theme, List<EquipmentRack> racks, List<InventoryLocation> locations) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = cardBackground(theme);

    final activeLocationId = _selectedPlacementLocationId ?? '';
    final placedRacks = racks.where((rack) =>
        rack.rackLocation?.locationRef == activeLocationId &&
        rack.rackLocation?.rowNumber != null &&
        rack.rackLocation?.columnNumber != null).toList();

    final gridMap = <String, EquipmentRack>{};
    for (final rack in placedRacks) {
      final row = rack.rackLocation!.rowNumber!;
      final col = rack.rackLocation!.columnNumber!;
      gridMap['$row,$col'] = rack;
    }

    int occupiedCount = placedRacks.length;
    double utilization = (occupiedCount / 100) * 100;

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                const Text(
                  'FACILITY GRID FLOOR PLAN (10x10)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('facilitySelector_${_selectedPlacementLocationId ?? "none"}'),
                    isExpanded: true,
                    value: _selectedPlacementLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Select Facility Location',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    dropdownColor: cardBg,
                    items: locations.map((loc) => DropdownMenuItem<String>(
                      value: loc.id,
                      child: Text(
                        '${loc.id} (${loc.type})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPlacementLocationId = val;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Grid Utilization: $occupiedCount / 100 cells occupied (${utilization.toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: Colors.blueAccent),
                    const SizedBox(width: 4),
                    const Text('Standard', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    const Text('Secure', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: isDark ? Colors.black38 : Colors.grey[200]),
                    const SizedBox(width: 4),
                    const Text('Empty (Click to Select)', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: 440,
                  height: 440,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E24) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      final row = (index ~/ 10) + 1;
                      final col = (index % 10) + 1;
                      final key = '$row,$col';
                      final rack = gridMap[key];

                      final isSelectedCell = _rowController.text == row.toString() &&
                                             _colController.text == col.toString() &&
                                             _rackFormLocationId == activeLocationId;

                      Color cellColor;
                      Widget cellContent;

                      if (rack != null) {
                        final isSecure = rack.rackClass.startsWith('rack-secure');
                        cellColor = isSecure ? Colors.redAccent : Colors.blueAccent;
                        cellContent = Tooltip(
                          message: 'Rack ID: ${rack.id}\nClass: ${rack.rackClass}\nGrid: Row $row, Col $col',
                          child: Center(
                            child: Text(
                              rack.id.length > 5 ? rack.id.substring(0, 5) : rack.id,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      } else {
                        cellColor = isSelectedCell 
                            ? Colors.teal.withValues(alpha: 0.3) 
                            : (isDark ? Colors.black38 : Colors.grey[200]!);
                        cellContent = Center(
                          child: Text(
                            '$row,$col',
                            style: TextStyle(
                              color: isDark ? Colors.white24 : Colors.black26,
                              fontSize: 8,
                            ),
                          ),
                        );
                      }

                      return InkWell(
                        key: Key('grid-cell-$row-$col'),
                        onTap: () {
                          setState(() {
                            _rowController.text = row.toString();
                            _colController.text = col.toString();
                            _rackFormLocationId = activeLocationId;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Auto-filled coordinates to Row $row, Column $col at facility $activeLocationId'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelectedCell 
                                  ? Colors.teal 
                                  : (isDark ? Colors.white10 : Colors.black12),
                              width: isSelectedCell ? 2 : 1,
                            ),
                          ),
                          child: cellContent,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme, EquipmentRackState state, List<InventoryLocation> locations) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = cardBackground(theme);

    final networkElements = sl<INetworkInventoryRepository>().getNetworkElements();

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.isEditing ? 'EDIT RACK PROPERTIES' : 'PROVISION NEW EQUIPMENT RACK',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _idController,
                enabled: !state.isEditing,
                decoration: InputDecoration(
                  labelText: 'Rack ID',
                  border: const OutlineInputBorder(),
                  errorText: state.idError,
                ),
                onChanged: (val) => context.read<EquipmentRackCubit>().validateField('id', val),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedRackClass,
                decoration: const InputDecoration(
                  labelText: 'Rack Classification (identityref)',
                  border: OutlineInputBorder(),
                ),
                dropdownColor: cardBg,
                items: const [
                  DropdownMenuItem(
                    value: 'rack-standard',
                    child: Text('rack-standard (Standard, Unsecured)'),
                  ),
                  DropdownMenuItem(
                    value: 'rack-secure-baseline',
                    child: Text('rack-secure-baseline (Baseline lockable)'),
                  ),
                  DropdownMenuItem(
                    value: 'rack-secure-medium',
                    child: Text('rack-secure-medium (Medium security)'),
                  ),
                  DropdownMenuItem(
                    value: 'rack-secure-high',
                    child: Text('rack-secure-high (High security biometric)'),
                  ),
                  DropdownMenuItem(
                    value: 'non-descendant',
                    child: Text('non-descendant (INVALID CLASS HIERARCHY)'),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedRackClass = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        labelText: 'Height (mm)',
                        border: const OutlineInputBorder(),
                        errorText: state.heightError,
                        helperText: 'Standard: 1866mm (42U)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => context.read<EquipmentRackCubit>().validateField('height', val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      decoration: InputDecoration(
                        labelText: 'Width (mm)',
                        border: const OutlineInputBorder(),
                        errorText: state.widthError,
                        helperText: 'Standard: 600mm',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => context.read<EquipmentRackCubit>().validateField('width', val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _depthController,
                      decoration: InputDecoration(
                        labelText: 'Depth (mm)',
                        border: const OutlineInputBorder(),
                        errorText: state.depthError,
                        helperText: 'Standard: 1000mm',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => context.read<EquipmentRackCubit>().validateField('depth', val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'PHYSICAL LOCATION & GRID PLACEMENT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _rackFormLocationId,
                decoration: const InputDecoration(
                  labelText: 'Physical Location Reference',
                  border: OutlineInputBorder(),
                  helperText: 'Select facility to place the rack on the floor plan',
                ),
                dropdownColor: cardBg,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Unassigned (None)'),
                  ),
                  ...locations.map((loc) => DropdownMenuItem<String>(
                    value: loc.id,
                    child: Text(
                      '${loc.id} (${loc.type})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                ],
                onChanged: (val) {
                  setState(() {
                    _rackFormLocationId = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rowController,
                      decoration: InputDecoration(
                        labelText: 'Grid Row',
                        border: const OutlineInputBorder(),
                        errorText: state.rowError,
                        helperText: 'Positive integer (>= 1)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => context.read<EquipmentRackCubit>().validateField('rowNumber', val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _colController,
                      decoration: InputDecoration(
                        labelText: 'Grid Column',
                        border: const OutlineInputBorder(),
                        errorText: state.colError,
                        helperText: 'Positive integer (>= 1)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => context.read<EquipmentRackCubit>().validateField('columnNumber', val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxVoltageController,
                      decoration: InputDecoration(
                        labelText: 'Max Voltage (V)',
                        border: const OutlineInputBorder(),
                        errorText: state.maxVoltageError,
                        helperText: 'Standard: 240V or 480V',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => context.read<EquipmentRackCubit>().validateField('maxVoltage', val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxAllocatedPowerController,
                      decoration: InputDecoration(
                        labelText: 'Max Allocated Power (W)',
                        border: const OutlineInputBorder(),
                        errorText: state.maxAllocatedPowerError,
                        helperText: 'E.g., 6000W or 12000W',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => context.read<EquipmentRackCubit>().validateField('maxAllocatedPower', val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _timestampController,
                      decoration: InputDecoration(
                        labelText: 'Recording Timestamp (ISO 8601)',
                        border: const OutlineInputBorder(),
                        errorText: state.timestampError,
                      ),
                      onChanged: (val) => context.read<EquipmentRackCubit>().validateField('timestamp', val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _timestampController.text = DateTime.now().toUtc().toIso8601String();
                        });
                        context.read<EquipmentRackCubit>().validateField('timestamp', _timestampController.text);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('SET NOW'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _validUntilController,
                      decoration: InputDecoration(
                        labelText: 'Expiration Timestamp (ISO 8601)',
                        border: const OutlineInputBorder(),
                        errorText: state.validUntilError,
                      ),
                      onChanged: (val) => context.read<EquipmentRackCubit>().validateField('validUntil', val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _validUntilController.text = DateTime.now().toUtc().add(const Duration(days: 365)).toIso8601String();
                        });
                        context.read<EquipmentRackCubit>().validateField('validUntil', _validUntilController.text);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('+1 YEAR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Divider(height: 32),
              const Text(
                'RACK-CONTAINED CHASSIS & POWER BUDGETS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (_editingRackContainedChassis.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No chassis mounted in this rack.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _editingRackContainedChassis.length,
                  itemBuilder: (context, index) {
                    final chassis = _editingRackContainedChassis[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1F3F4),
                      child: ListTile(
                        dense: true,
                        title: Text('Slot U${chassis.relativePosition}: ${chassis.neRef} / ${chassis.componentRef}'),
                        subtitle: Text('Power Draw: ${chassis.powerConsumption} W'),
                        trailing: IconButton(
                          key: ValueKey('delete-chassis-$index'),
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          onPressed: () {
                            setState(() {
                              _editingRackContainedChassis.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                  color: isDark ? const Color(0xFF242526) : const Color(0xFFFAFAFA),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Mount New Chassis',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: const ValueKey('rack-chassis-u-field'),
                            controller: _chassisUController,
                            decoration: const InputDecoration(
                              labelText: 'U-Slot (1-255)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            key: const ValueKey('rack-chassis-power-field'),
                            controller: _chassisPowerController,
                            decoration: const InputDecoration(
                              labelText: 'Power Draw (W)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('rack-chassis-ne-dropdown'),
                            isExpanded: true,
                            value: _chassisNeRef,
                            decoration: const InputDecoration(
                              labelText: 'Network Element Ref',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            dropdownColor: cardBg,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Select NE'),
                              ),
                              ...networkElements.map((ne) => DropdownMenuItem<String>(
                                value: ne.neId,
                                child: Text(ne.neId),
                              )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _chassisNeRef = val;
                                _chassisComponentRef = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('rack-chassis-component-dropdown'),
                            isExpanded: true,
                            value: _chassisComponentRef,
                            decoration: const InputDecoration(
                              labelText: 'Component Ref',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            dropdownColor: cardBg,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Select Component'),
                              ),
                              if (_chassisNeRef != null && networkElements.any((ne) => ne.neId == _chassisNeRef))
                                ...(networkElements.firstWhere((ne) => ne.neId == _chassisNeRef).componentIds)
                                    .map((compId) => DropdownMenuItem<String>(
                                          value: compId,
                                          child: Text(compId),
                                        )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _chassisComponentRef = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_chassisError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _chassisError!,
                        style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      key: const ValueKey('mount-chassis-button'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Mount Chassis to Slot'),
                      onPressed: () {
                        final uText = _chassisUController.text.trim();
                        final pText = _chassisPowerController.text.trim();
                        final neRef = _chassisNeRef;
                        final compRef = _chassisComponentRef;

                        if (uText.isEmpty || pText.isEmpty || neRef == null || compRef == null) {
                          setState(() {
                            _chassisError = 'Please fill all chassis fields.';
                          });
                          return;
                        }

                        final slot = int.tryParse(uText);
                        if (slot == null || slot < 1 || slot > 255) {
                          setState(() {
                            _chassisError = 'U-Slot must be between 1 and 255.';
                          });
                          return;
                        }

                        final power = int.tryParse(pText);
                        if (power == null || power < 0 || power > 65535) {
                          setState(() {
                            _chassisError = 'Power must be between 0 and 65535 W.';
                          });
                          return;
                        }

                        if (_editingRackContainedChassis.any((c) => c.relativePosition == slot)) {
                          setState(() {
                            _chassisError = 'Chassis slot conflict at U-slot position $slot.';
                          });
                          return;
                        }

                        final currentTotalPower = _editingRackContainedChassis.fold<int>(0, (sum, c) => sum + c.powerConsumption);
                        final maxPower = int.tryParse(_maxAllocatedPowerController.text.trim()) ?? 0;
                        if (currentTotalPower + power > maxPower) {
                          setState(() {
                            _chassisError = 'Mounting this chassis exceeds max allocated power limit of $maxPower W.';
                          });
                          return;
                        }

                        setState(() {
                          _editingRackContainedChassis.add(RackContainedChassis(
                            relativePosition: slot,
                            neRef: neRef,
                            componentRef: compRef,
                            powerConsumption: power,
                          ));
                          _chassisUController.clear();
                          _chassisPowerController.clear();
                          _chassisNeRef = null;
                          _chassisComponentRef = null;
                          _chassisError = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (state.generalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.generalError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (state.isEditing) ...[
                    OutlinedButton(
                      onPressed: () {
                        context.read<EquipmentRackCubit>().setEditing(false);
                        context.read<EquipmentRackCubit>().selectRack(null);
                        _clearForm();
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      try {
                        final idVal = state.isEditing && state.selectedRack != null
                            ? state.selectedRack!.id
                            : _idController.text.trim();
                        final rackClassVal = _selectedRackClass ?? 'rack-standard';
                        final heightStr = _heightController.text.trim();
                        final widthStr = _widthController.text.trim();
                        final depthStr = _depthController.text.trim();
                        final timestampStr = _timestampController.text.trim();
                        final validUntilStr = _validUntilController.text.trim();
                        final locationRefVal = _rackFormLocationId ?? '';
                        final rowStr = _rowController.text.trim();
                        final colStr = _colController.text.trim();
                        final maxVoltageStr = _maxVoltageController.text.trim();
                        final maxAllocatedPowerStr = _maxAllocatedPowerController.text.trim();

                        // Basic validations
                        if (idVal.isEmpty) throw const FormatException('Rack ID cannot be empty');
                        if (heightStr.isEmpty) throw const FormatException('Rack height must be a positive integer between 1 and 65535 mm');
                        final height = int.tryParse(heightStr);
                        if (height == null || height < 1 || height > 65535) {
                          throw const FormatException('Rack height must be a positive integer between 1 and 65535 mm');
                        }
                        if (widthStr.isEmpty) throw const FormatException('Rack width must be a positive integer between 1 and 65535 mm');
                        final width = int.tryParse(widthStr);
                        if (width == null || width < 1 || width > 65535) {
                          throw const FormatException('Rack width must be a positive integer between 1 and 65535 mm');
                        }
                        if (depthStr.isEmpty) throw const FormatException('Rack depth must be a positive integer between 1 and 65535 mm');
                        final depth = int.tryParse(depthStr);
                        if (depth == null || depth < 1 || depth > 65535) {
                          throw const FormatException('Rack depth must be a positive integer between 1 and 65535 mm');
                        }

                        if (timestampStr.isEmpty) throw const FormatException('Recording timestamp is required');
                        final timestamp = DateTime.parse(timestampStr);

                        if (validUntilStr.isEmpty) throw const FormatException('Expiration timestamp is required');
                        final validUntil = DateTime.parse(validUntilStr);
                        if (!validUntil.isAfter(timestamp)) {
                          throw const FormatException('Rack valid-until timestamp must be after recording timestamp');
                        }

                        if (locationRefVal.isNotEmpty) {
                          if (rowStr.isEmpty) throw const FormatException('Row number is required.');
                          final row = int.tryParse(rowStr);
                          if (row == null || row <= 0) {
                            throw const FormatException('Row number must be a positive uint32 integer');
                          }
                          if (colStr.isEmpty) throw const FormatException('Column number is required.');
                          final col = int.tryParse(colStr);
                          if (col == null || col <= 0) {
                            throw const FormatException('Column number must be a positive uint32 integer');
                          }
                        }

                        // Check identityref valid class (descendant of rack-class-type)
                        if (rackClassVal != 'rack-standard' &&
                            rackClassVal != 'rack-secure-high' &&
                            rackClassVal != 'rack-secure-medium' &&
                            rackClassVal != 'rack-standard-42u') {
                          throw FormatException('Identityref "$rackClassVal" is not a valid descendant of rack-class-type');
                        }

                        // Let the repository perform deeper validations (containedChassis slot/power/exist etc.)
                        final networkElements = sl<INetworkInventoryRepository>().getNetworkElements();
                        final Map<String, List<String>> neComponents = {
                          for (var ne in networkElements) ne.neId: ne.componentIds
                        };
                        final tempRack = EquipmentRack(
                          id: idVal,
                          rackClass: rackClassVal,
                          height: height,
                          width: width,
                          depth: depth,
                          timestamp: timestamp,
                          validUntil: validUntil,
                          rackLocation: locationRefVal.isNotEmpty
                              ? RackLocation(
                                  locationRef: locationRefVal,
                                  rowNumber: int.parse(rowStr),
                                  columnNumber: int.parse(colStr),
                                )
                              : null,
                          maxVoltage: maxVoltageStr.isNotEmpty ? int.parse(maxVoltageStr) : 240,
                          maxAllocatedPower: maxAllocatedPowerStr.isNotEmpty ? int.parse(maxAllocatedPowerStr) : 6000,
                          containedChassis: _editingRackContainedChassis,
                        );
                        // Call validator directly to throw if there are slot conflicts, power violations, unregistered locations, etc.
                        final validLocs = Set<String>.from(state.validLocationIds);
                        EquipmentRackValidator.validate(
                          id: tempRack.id,
                          rackClass: tempRack.rackClass,
                          height: tempRack.height,
                          width: tempRack.width,
                          depth: tempRack.depth,
                          timestamp: tempRack.timestamp,
                          validUntil: tempRack.validUntil,
                          rackLocation: tempRack.rackLocation,
                          maxVoltage: tempRack.maxVoltage,
                          maxAllocatedPower: tempRack.maxAllocatedPower,
                          containedChassis: tempRack.containedChassis,
                          validNeComponents: neComponents,
                          validLocationIds: validLocs,
                        );

                        if (state.isEditing && state.selectedRack != null) {
                          context.read<EquipmentRackCubit>().updateRack(
                            id: idVal,
                            rackClass: rackClassVal,
                            rawHeight: heightStr,
                            rawWidth: widthStr,
                            rawDepth: depthStr,
                            rawTimestamp: timestampStr,
                            rawValidUntil: validUntilStr,
                            locationRef: locationRefVal,
                            rawRow: rowStr,
                            rawCol: colStr,
                            rawMaxVoltage: maxVoltageStr,
                            rawMaxAllocatedPower: maxAllocatedPowerStr,
                            containedChassis: _editingRackContainedChassis,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully updated rack $idVal'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          context.read<EquipmentRackCubit>().addRack(
                            id: idVal,
                            rackClass: rackClassVal,
                            rawHeight: heightStr,
                            rawWidth: widthStr,
                            rawDepth: depthStr,
                            rawTimestamp: timestampStr,
                            rawValidUntil: validUntilStr,
                            locationRef: locationRefVal,
                            rawRow: rowStr,
                            rawCol: colStr,
                            rawMaxVoltage: maxVoltageStr,
                            rawMaxAllocatedPower: maxAllocatedPowerStr,
                            containedChassis: _editingRackContainedChassis,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully added rack $idVal'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        _clearForm();
                        context.read<EquipmentRackCubit>().setEditing(false);
                      } catch (e) {
                        final errMsg = formatError(e);
                        context.read<EquipmentRackCubit>().setGeneralError(errMsg);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(state.isEditing ? 'UPDATE PROPERTIES' : 'PROVISION RACK'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<EquipmentRackCubit>().resetAll();
                },
                icon: const Icon(Icons.restore),
                label: const Text('RESET SYSTEM RACKS DEFAULTS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListPane(ThemeData theme, EquipmentRackState state) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = cardBackground(theme);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final listContent = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.racks.length,
      itemBuilder: (context, index) {
        final rack = state.racks[index];
        final isSelected = state.selectedRack?.id == rack.id;
        
        Color securityColor;
        switch (rack.rackClass) {
          case 'rack-secure-baseline':
            securityColor = Colors.green;
            break;
          case 'rack-secure-medium':
            securityColor = Colors.orange;
            break;
          case 'rack-secure-high':
            securityColor = Colors.red;
            break;
          default:
            securityColor = const Color(0xFF3367D6);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected 
                ? securityColor.withValues(alpha: 0.1) 
                : (isDark ? const Color(0xFF1E1E24) : const Color(0xFFF8F9FA)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                color: isSelected ? securityColor : (isDark ? Colors.white10 : Colors.black12),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                children: [
                  Icon(Icons.grid_view, color: securityColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rack.id,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Class: ${rack.rackClass}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  Text(
                    'Dimensions: ${rack.height} x ${rack.width} x ${rack.depth} mm (${(rack.height / 44.45).round()}U)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      context.read<EquipmentRackCubit>().selectRack(rack);
                      context.read<EquipmentRackCubit>().setEditing(true);
                      _populateForm(rack);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                    onPressed: () {
                      context.read<EquipmentRackCubit>().deleteRack(rack.id);
                    },
                  ),
                ],
              ),
              onTap: () {
                context.read<EquipmentRackCubit>().selectRack(rack);
              },
            ),
          ),
        );
      },
    );

    final visualizerContent = state.selectedRack != null
        ? USlotGridVisualizer(
            rack: state.selectedRack!,
            isDark: isDark,
          )
        : const Center(
            child: Text('No Rack Selected'),
          );

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'EQUIPMENT RACKS REGISTRY & U-SLOTS VISUALIZER',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isDesktop)
              SizedBox(
                height: 650,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: SingleChildScrollView(child: listContent)),
                    const VerticalDivider(width: 32),
                    Expanded(flex: 4, child: visualizerContent),
                  ],
                ),
              )
            else ...[
              listContent,
              const SizedBox(height: 24),
              SizedBox(height: 400, child: visualizerContent),
            ],
          ],
        ),
      ),
    );
  }
}
