import 'package:cogctl_ux/utils/theme_utils.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/features/geo_location/domain/geo_location.dart';
import 'package:cogctl_ux/features/geo_location/domain/repositories/i_location_repository.dart';
import 'package:cogctl_ux/features/geo_location/presentation/cubit/geo_location_cubit.dart';
import 'package:cogctl_ux/features/geo_location/presentation/cubit/geo_location_state.dart';
import 'package:cogctl_ux/core/widgets/temporal_expiry_tracker.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:math';

class GeoLocationScreen extends StatelessWidget {
  const GeoLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GeoLocationCubit(sl<ILocationRepository>()),
      child: const _GeoLocationView(),
    );
  }
}

class _GeoLocationView extends StatefulWidget {
  const _GeoLocationView();

  @override
  State<_GeoLocationView> createState() => _GeoLocationViewState();
}

class _GeoLocationViewState extends State<_GeoLocationView> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _bodyController = TextEditingController();
  final _datumController = TextEditingController();
  final _altSystemController = TextEditingController();
  final _coordAccController = TextEditingController();
  final _heightAccController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _heightController = TextEditingController();

  // Cartesian controllers
  final _xController = TextEditingController();
  final _yController = TextEditingController();
  final _zController = TextEditingController();

  // Velocity controllers
  final _vNorthController = TextEditingController();
  final _vEastController = TextEditingController();
  final _vUpController = TextEditingController();

  // Expiry / Temporal Validity controllers
  final _timestampController = TextEditingController();
  final _validUntilController = TextEditingController();

  // Debounced input subjects
  final _inputSubjects = <String, PublishSubject<String>>{};

  void _onFieldChanged(String fieldName, String value) {
    _inputSubjects.putIfAbsent(fieldName, () {
      final subject = PublishSubject<String>();
      subject.debounceTime(const Duration(milliseconds: 300)).listen((val) {
        if (mounted) {
          context.read<GeoLocationCubit>().validateField(fieldName, val);
          if (fieldName == 'vNorth' || fieldName == 'vEast' || fieldName == 'vUp') {
            _updateVelocityMath();
          }
        }
      });
      return subject;
    }).add(value);
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _datumController.dispose();
    _altSystemController.dispose();
    _coordAccController.dispose();
    _heightAccController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _heightController.dispose();
    _xController.dispose();
    _yController.dispose();
    _zController.dispose();
    _vNorthController.dispose();
    _vEastController.dispose();
    _vUpController.dispose();
    _timestampController.dispose();
    _validUntilController.dispose();
    for (final subject in _inputSubjects.values) {
      subject.close();
    }
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _bodyController.clear();
      _datumController.clear();
      _altSystemController.clear();
      _coordAccController.clear();
      _heightAccController.clear();
      _latController.clear();
      _lonController.clear();
      _heightController.clear();
      _xController.clear();
      _yController.clear();
      _zController.clear();
      _vNorthController.clear();
      _vEastController.clear();
      _vUpController.clear();
      _timestampController.clear();
      _validUntilController.clear();
    });
    context.read<GeoLocationCubit>().setCoordinateMode('Ellipsoidal');
  }

  void _submitForm() {
    context.read<GeoLocationCubit>().addRecord(
      rawBody: _bodyController.text,
      rawDatum: _datumController.text,
      rawAlt: _altSystemController.text,
      rawCoord: _coordAccController.text,
      rawHeightAcc: _heightAccController.text,
      rawLat: _latController.text,
      rawLon: _lonController.text,
      rawHeightVal: _heightController.text,
      rawX: _xController.text,
      rawY: _yController.text,
      rawZ: _zController.text,
      rawVNorth: _vNorthController.text,
      rawVEast: _vEastController.text,
      rawVUp: _vUpController.text,
      rawTimestamp: _timestampController.text,
      rawValidUntil: _validUntilController.text,
    );
  }

  void _updateVelocityMath() {
    context.read<GeoLocationCubit>().updateComputedVelocity(
      vNorthRaw: _vNorthController.text,
      vEastRaw: _vEastController.text,
      vUpRaw: _vUpController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocConsumer<GeoLocationCubit, GeoLocationState>(
      listener: (context, state) {
        if (state.generalError == null && state.records.isNotEmpty) {
          // You could optionally show success feedback here if needed,
          // but we just follow parity of main.dart.
        }
      },
      builder: (context, state) {
        final content = isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSDNStatusSummary(theme, state.records),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildFormCard(theme, state)),
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
                    _buildSDNStatusSummary(theme, state.records),
                    _buildFormCard(theme, state),
                    const SizedBox(height: 24),
                    _buildListPane(theme, state),
                  ],
                ),
              );

        return content;
      },
    );
  }

  Widget _buildSDNStatusSummary(ThemeData theme, List<GeoLocation> records) {
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    int total = records.length;
    int terrestrial = records.where((r) => r.referenceFrame.astronomicalBody == 'earth' && ((r.networkDomain?.contains('Terrestrial') ?? false) || (r.networkDomain?.contains('Mobile') ?? false))).length;
    int submarine = records.where((r) => r.networkDomain?.contains('Submarine') ?? false).length;
    int space = records.where((r) => r.referenceFrame.astronomicalBody != 'earth' || ((r.networkDomain?.contains('Satellite') ?? false) || (r.networkDomain?.contains('Space') ?? false))).length;
    int quantum = records.where((r) => (r.networkDomain?.contains('Quantum') ?? false) || (r.networkDomain?.contains('QKD') ?? false)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Cognitive SDN Controller',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'L0-L4 ONLINE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL NODES', '$total', Icons.hub, Colors.blue),
              _buildMiniStatusCard(theme, cardBg, borderSide, 'FIBER & WIRELESS', '$terrestrial', Icons.settings_ethernet, Colors.amber),
              _buildMiniStatusCard(theme, cardBg, borderSide, 'SUBSEA TRANSOCEANIC', '$submarine', Icons.waves, Colors.teal),
              _buildMiniStatusCard(theme, cardBg, borderSide, 'NTN & DEEP SPACE', '$space', Icons.rocket_launch, Colors.deepOrange),
              _buildMiniStatusCard(theme, cardBg, borderSide, 'QUANTUM QKD KEYS', '$quantum', Icons.compare_arrows, Colors.purple),
            ],
          ),
        ],
      ),
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

  Widget _buildFormCard(ThemeData theme, GeoLocationState state) {
    final cardBg = cardBackground(theme);

    final networkDomains = [
      'Terrestrial Fiber (L0-L4)',
      'Mobile / Wireless (L1-L4)',
      'Submarine Cable (Subsea)',
      'Non-Terrestrial Network (NTN)',
      'Deep Space Network (DSN)',
      'Quantum Key Distribution (QKD)',
    ];

    return Card(
      color: cardBg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Configure Reference Frame',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'YANG CONFIG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (state.generalError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.generalError!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Network DomainDropdown
                DropdownButtonFormField<String>(
                  value: state.selectedNetworkDomain,
                  decoration: InputDecoration(
                    labelText: 'SDN Network Domain Association',
                    prefixIcon: const Icon(Icons.hub, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onChanged: (String? val) {
                    if (val != null) {
                      context.read<GeoLocationCubit>().setSelectedNetworkDomain(val);
                    }
                  },
                  items: networkDomains.map((String domain) {
                    return DropdownMenuItem<String>(
                      value: domain,
                      child: Text(domain),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Astronomical Body
                TextField(
                  controller: _bodyController,
                  decoration: InputDecoration(
                    labelText: 'Astronomical Body (Default: earth)',
                    hintText: 'e.g. Earth, Mars, Moon',
                    errorText: state.bodyError,
                    prefixIcon: const Icon(Icons.public, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onChanged: (val) => _onFieldChanged('body', val),
                ),
                const SizedBox(height: 16),

                // Geodetic Datum
                TextField(
                  controller: _datumController,
                  decoration: InputDecoration(
                    labelText: 'Geodetic Datum (Default: wgs-84)',
                    hintText: 'e.g. WGS-84, Mars-2015',
                    errorText: state.datumError,
                    prefixIcon: const Icon(Icons.grid_on, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onChanged: (val) => _onFieldChanged('datum', val),
                ),
                const SizedBox(height: 16),

                // Feature Flag: alternate-systems
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Simulate alternate-systems flag',
                      style: TextStyle(fontSize: 14),
                    ),
                    Switch(
                      value: state.alternateSystemsEnabled,
                      onChanged: (val) {
                        context.read<GeoLocationCubit>().setAlternateSystemsEnabled(val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Alternate System
                if (state.alternateSystemsEnabled) ...[
                  TextField(
                    controller: _altSystemController,
                    decoration: InputDecoration(
                      labelText: 'Alternate System (Optional)',
                      hintText: 'e.g. ECEF, Lunar-System',
                      errorText: state.altSystemError,
                      prefixIcon: const Icon(Icons.swap_horiz, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onChanged: (val) => _onFieldChanged('altSystem', val),
                  ),
                  const SizedBox(height: 16),
                ],

                // Coordinate Accuracy
                TextField(
                  controller: _coordAccController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Coordinate Accuracy (decimal)',
                    hintText: 'e.g. 0.0005',
                    errorText: state.coordAccError,
                    prefixIcon: const Icon(Icons.gps_fixed, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onChanged: (val) => _onFieldChanged('coordAcc', val),
                ),
                const SizedBox(height: 16),

                // Height Accuracy
                TextField(
                  controller: _heightAccController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Height Accuracy (decimal)',
                    hintText: 'e.g. 0.001',
                    errorText: state.heightAccError,
                    prefixIcon: const Icon(Icons.height, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onChanged: (val) => _onFieldChanged('heightAcc', val),
                ),
                const SizedBox(height: 16),

                const Divider(height: 32),
                Text(
                  'Location Coordinates Choice',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    return ToggleButtons(
                      isSelected: [
                        state.coordinateMode == 'Ellipsoidal',
                        state.coordinateMode == 'Cartesian',
                      ],
                      onPressed: (index) {
                        final mode = index == 0 ? 'Ellipsoidal' : 'Cartesian';
                        context.read<GeoLocationCubit>().setCoordinateMode(mode);
                      },
                      borderRadius: BorderRadius.circular(4),
                      constraints: BoxConstraints(
                        minWidth: (constraints.maxWidth - 4) / 2,
                        minHeight: 40,
                      ),
                      children: const [
                        Text('Ellipsoidal (Lat/Lon/H)'),
                        Text('Cartesian (X/Y/Z)'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                if (state.coordinateMode == 'Ellipsoidal') ...[
                  // Latitude
                  TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Latitude (decimal degrees)',
                      hintText: 'e.g. 37.7749',
                      errorText: state.latError,
                      prefixIcon: const Icon(Icons.explore, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onChanged: (val) => _onFieldChanged('lat', val),
                  ),
                  const SizedBox(height: 16),

                  // Longitude
                  TextField(
                    controller: _lonController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Longitude (decimal degrees)',
                      hintText: 'e.g. -122.4194',
                      errorText: state.lonError,
                      prefixIcon: const Icon(Icons.explore, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onChanged: (val) => _onFieldChanged('lon', val),
                  ),
                  const SizedBox(height: 16),

                  // Height
                  TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Height (meters, optional)',
                      hintText: 'e.g. 10.5',
                      errorText: state.heightError,
                      prefixIcon: const Icon(Icons.vertical_align_top, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onChanged: (val) => _onFieldChanged('height', val),
                  ),
                ] else ...[
                  // X coordinate
                  TextField(
                    controller: _xController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'X Coordinate (meters)',
                      hintText: 'e.g. 6378137.123456',
                      errorText: state.xError,
                      prefixIcon: const Icon(Icons.gps_fixed, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onChanged: (val) => _onFieldChanged('x', val),
                  ),
                  const SizedBox(height: 16),

                  // Y coordinate
                  TextField(
                    controller: _yController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Y Coordinate (meters)',
                      hintText: 'e.g. 0.0',
                      errorText: state.yError,
                      prefixIcon: const Icon(Icons.gps_fixed, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onChanged: (val) => _onFieldChanged('y', val),
                  ),
                  const SizedBox(height: 16),

                  // Z coordinate
                  TextField(
                    controller: _zController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Z Coordinate (meters)',
                      hintText: 'e.g. 0.0',
                      errorText: state.zError,
                      prefixIcon: const Icon(Icons.gps_fixed, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onChanged: (val) => _onFieldChanged('z', val),
                  ),
                ],
                const SizedBox(height: 24),

                const Divider(height: 32),
                Text(
                  'Motion Velocity Vector (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),

                // v-north
                TextField(
                  controller: _vNorthController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Northward Velocity (v-north, m/s)',
                    hintText: 'e.g. 10.0',
                    errorText: state.vNorthError,
                    prefixIcon: const Icon(Icons.north, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onChanged: (val) => _onFieldChanged('vNorth', val),
                ),
                const SizedBox(height: 16),

                // v-east
                TextField(
                  controller: _vEastController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Eastward Velocity (v-east, m/s)',
                    hintText: 'e.g. 5.5',
                    errorText: state.vEastError,
                    prefixIcon: const Icon(Icons.east, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onChanged: (val) => _onFieldChanged('vEast', val),
                ),
                const SizedBox(height: 16),

                // v-up
                TextField(
                  controller: _vUpController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Upward Velocity (v-up, m/s)',
                    hintText: 'e.g. 0.1',
                    errorText: state.vUpError,
                    prefixIcon: const Icon(Icons.arrow_upward, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onChanged: (val) => _onFieldChanged('vUp', val),
                ),
                const SizedBox(height: 16),

                // Computed Speed & Heading Display
                if (state.computedSpeed != null && state.computedHeading != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.speed, color: theme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Live Computed Horizontal Speed: ${state.computedSpeed!.toStringAsFixed(2)} m/s (${(state.computedSpeed! * 3.6).toStringAsFixed(2)} km/h)  |  Heading: ${state.computedHeading!.toStringAsFixed(2)}°',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(height: 32),
                Text(
                  'Temporal Validity (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _timestampController,
                        decoration: InputDecoration(
                          labelText: 'Recording Timestamp (ISO 8601 UTC)',
                          hintText: 'e.g. 2026-06-01T12:00:00Z',
                          errorText: state.timestampError,
                          prefixIcon: const Icon(Icons.access_time, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onChanged: (val) => _onFieldChanged('timestamp', val),
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
                          context.read<GeoLocationCubit>().validateField('timestamp', _timestampController.text);
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _validUntilController,
                        decoration: InputDecoration(
                          labelText: 'Valid Until (Expiration, ISO 8601 UTC)',
                          hintText: 'e.g. 2026-06-02T12:00:00Z',
                          errorText: state.validUntilError,
                          prefixIcon: const Icon(Icons.timer_off, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onChanged: (val) => _onFieldChanged('validUntil', val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        final base = DateTime.tryParse(_timestampController.text.trim()) ?? DateTime.now().toUtc();
                        setState(() {
                          _validUntilController.text = base.add(const Duration(hours: 1)).toUtc().toIso8601String();
                        });
                        context.read<GeoLocationCubit>().validateField('validUntil', _validUntilController.text);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('+1 Hour'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        final base = DateTime.tryParse(_timestampController.text.trim()) ?? DateTime.now().toUtc();
                        setState(() {
                          _validUntilController.text = base.add(const Duration(days: 1)).toUtc().toIso8601String();
                        });
                        context.read<GeoLocationCubit>().validateField('validUntil', _validUntilController.text);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('+1 Day'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        final base = DateTime.tryParse(_timestampController.text.trim()) ?? DateTime.now().toUtc();
                        setState(() {
                          _validUntilController.text = base.add(const Duration(days: 7)).toUtc().toIso8601String();
                        });
                        context.read<GeoLocationCubit>().validateField('validUntil', _validUntilController.text);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('+7 Days'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('RESET'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('SUBMIT REGISTER'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListPane(ThemeData theme, GeoLocationState state) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final Widget listContent = state.records.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                children: [
                  Icon(Icons.storage, size: 48, color: theme.hintColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'Database registry is empty.',
                    style: TextStyle(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: state.records.length,
            itemBuilder: (context, index) {
              final rec = state.records[index];
              final frame = rec.referenceFrame;
              final system = frame.geodeticSystem;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.hub, color: theme.primaryColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                frame.astronomicalBody.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (rec.networkDomain != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    rec.networkDomain!,
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          TemporalExpiryTracker(
                            validUntil: rec.validUntil,
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.5),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('GEODETIC DATUM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  system.geodeticDatum,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          if (frame.alternateSystem != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ALTERNATE SYSTEM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    frame.alternateSystem!,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (system.coordAccuracy != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('COORD ACCURACY', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('${system.coordAccuracy}'),
                                ],
                              ),
                            ),
                          if (system.heightAccuracy != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('HEIGHT ACCURACY', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('${system.heightAccuracy} meters'),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (rec.location != null) ...[
                        const Divider(height: 24, thickness: 0.5),
                        if (rec.location is EllipsoidCoordinate)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('LATITUDE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(rec.location as EllipsoidCoordinate).latitude}°',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('LONGITUDE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(rec.location as EllipsoidCoordinate).longitude}°',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              if ((rec.location as EllipsoidCoordinate).height != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('HEIGHT', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${(rec.location as EllipsoidCoordinate).height} m',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        if (rec.location is CartesianCoordinate)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('X COORDINATE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(rec.location as CartesianCoordinate).x} m',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Y COORDINATE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(rec.location as CartesianCoordinate).y} m',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Z COORDINATE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(rec.location as CartesianCoordinate).z} m',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                      if (rec.timestamp != null || rec.validUntil != null) ...[
                        const Divider(height: 24, thickness: 0.5),
                        const Text('TEMPORAL VALIDITY', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (rec.timestamp != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('RECORDED TIMESTAMP', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      rec.timestamp!.toUtc().toIso8601String(),
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            if (rec.validUntil != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('VALID UNTIL', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      rec.validUntil!.toUtc().toIso8601String(),
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (rec.velocity != null) ...[
                        const Divider(height: 24, thickness: 0.5),
                        const Text('MOTION VELOCITY VECTOR', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (rec.velocity!.vNorth != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('V-NORTH', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${rec.velocity!.vNorth} m/s',
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            if (rec.velocity!.vEast != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('V-EAST', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${rec.velocity!.vEast} m/s',
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            if (rec.velocity!.vUp != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('V-UP', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${rec.velocity!.vUp} m/s',
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (rec.velocity!.vNorth != null && rec.velocity!.vEast != null) ...[
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final vn = rec.velocity!.vNorth!;
                              final ve = rec.velocity!.vEast!;
                              final speed = sqrt(vn * vn + ve * ve);
                              double heading = atan2(ve, vn) * 180 / pi;
                              if (heading < 0) heading += 360.0;
                              return Text(
                                'Horizontal Speed: ${speed.toStringAsFixed(3)} m/s (${(speed * 3.6).toStringAsFixed(2)} km/h)  |  Heading: ${heading.toStringAsFixed(2)}°',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Console Active Registries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            OutlinedButton.icon(
              icon: Icon(Icons.delete_sweep, size: 16, color: theme.colorScheme.error),
              label: Text(
                'PURGE DB',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              ),
              onPressed: () {
                context.read<GeoLocationCubit>().clearRecords();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        isDesktop ? Expanded(child: listContent) : listContent,
      ],
    );
  }
}
