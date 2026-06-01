import 'package:flutter/material.dart';
import 'models/geo_location.dart';
import 'services/mock_location_service.dart';

void main() {
  runApp(const CogctlUxApp());
}

class CogctlUxApp extends StatelessWidget {
  const CogctlUxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geographic Reference Frame Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const ReferenceFrameDashboard(),
    );
  }
}

class ReferenceFrameDashboard extends StatefulWidget {
  const ReferenceFrameDashboard({super.key});

  @override
  State<ReferenceFrameDashboard> createState() => _ReferenceFrameDashboardState();
}

class _ReferenceFrameDashboardState extends State<ReferenceFrameDashboard> {
  final MockLocationService _service = MockLocationService();
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _bodyController = TextEditingController();
  final _datumController = TextEditingController();
  final _altSystemController = TextEditingController();
  final _coordAccController = TextEditingController();
  final _heightAccController = TextEditingController();

  // Feature flag simulation for alternate-system
  bool _alternateSystemsEnabled = true;

  // Validation messages
  String? _generalError;
  String? _bodyError;
  String? _datumError;
  String? _coordAccError;
  String? _heightAccError;

  // List of location records
  List<GeoLocation> _records = [];

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _records = _service.getLocations();
    });
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _datumController.dispose();
    _altSystemController.dispose();
    _coordAccController.dispose();
    _heightAccController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _bodyController.clear();
    _datumController.clear();
    _altSystemController.clear();
    _coordAccController.clear();
    _heightAccController.clear();
    setState(() {
      _generalError = null;
      _bodyError = null;
      _datumError = null;
      _coordAccError = null;
      _heightAccError = null;
    });
  }

  void _submitForm() {
    setState(() {
      _generalError = null;
      _bodyError = null;
      _datumError = null;
      _coordAccError = null;
      _heightAccError = null;
    });

    final rawBody = _bodyController.text.trim();
    final rawDatum = _datumController.text.trim();
    final rawAlt = _altSystemController.text.trim();
    final rawCoord = _coordAccController.text.trim();
    final rawHeight = _heightAccController.text.trim();

    // 1. Determine defaults
    String astronomicalBody = rawBody.isEmpty ? 'earth' : ReferenceFrameValidator.normalize(rawBody);
    String geodeticDatum = rawDatum.isEmpty 
        ? (astronomicalBody == 'earth' ? 'wgs-84' : '') 
        : ReferenceFrameValidator.normalize(rawDatum);

    // 2. Perform validation checks
    bool hasError = false;

    // Validate Astronomical Body pattern
    try {
      ReferenceFrameValidator.validateAstronomicalBody(astronomicalBody);
    } catch (e) {
      setState(() {
        _bodyError = e.toString().replaceFirst('FormatException: ', '');
      });
      hasError = true;
    }

    // Validate Geodetic Datum pattern
    try {
      ReferenceFrameValidator.validateGeodeticDatum(geodeticDatum);
    } catch (e) {
      setState(() {
        _datumError = e.toString().replaceFirst('FormatException: ', '');
      });
      hasError = true;
    }

    // Parse & Validate Coordinate Accuracy
    double? coordAccuracy;
    if (rawCoord.isNotEmpty) {
      try {
        coordAccuracy = ReferenceFrameValidator.parseAccuracy(rawCoord);
      } catch (e) {
        setState(() {
          _coordAccError = e.toString().replaceFirst('FormatException: ', '');
        });
        hasError = true;
      }
    }

    // Parse & Validate Height Accuracy
    double? heightAccuracy;
    if (rawHeight.isNotEmpty) {
      try {
        heightAccuracy = ReferenceFrameValidator.parseAccuracy(rawHeight);
      } catch (e) {
        setState(() {
          _heightAccError = e.toString().replaceFirst('FormatException: ', '');
        });
        hasError = true;
      }
    }

    if (hasError) {
      return;
    }

    // 3. Construct objects
    final geodeticSystem = GeodeticSystem(
      geodeticDatum: geodeticDatum,
      coordAccuracy: coordAccuracy,
      heightAccuracy: heightAccuracy,
    );

    final referenceFrame = ReferenceFrame(
      astronomicalBody: astronomicalBody,
      alternateSystem: _alternateSystemsEnabled && rawAlt.isNotEmpty ? rawAlt : null,
      geodeticSystem: geodeticSystem,
    );

    final location = GeoLocation(referenceFrame: referenceFrame);

    // 4. Save to Mock DB
    try {
      _service.addLocation(location);
      _clearForm();
      _refreshList();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geographic Reference Frame registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _generalError = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.language, color: Colors.indigoAccent),
            SizedBox(width: 10),
            Text(
              'RFC 9179 Geo-Location Specs',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _buildFormCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: _buildListPane()),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFormCard(),
                      const SizedBox(height: 24),
                      _buildListPane(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Register Reference Frame',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigoAccent,
                ),
              ),
              const SizedBox(height: 16),
              if (_generalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Astronomical Body
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: 'Astronomical Body (Default: earth)',
                  hintText: 'e.g. Earth, Mars, Moon',
                  errorText: _bodyError,
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Geodetic Datum
              TextField(
                controller: _datumController,
                decoration: InputDecoration(
                  labelText: 'Geodetic Datum (Default: wgs-84)',
                  hintText: 'e.g. WGS-84, Mars-2015',
                  errorText: _datumError,
                  prefixIcon: const Icon(Icons.grid_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Feature Flag: alternate-systems
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enable Alternate Systems'),
                  Switch(
                    value: _alternateSystemsEnabled,
                    onChanged: (val) {
                      setState(() {
                        _alternateSystemsEnabled = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Alternate System
              if (_alternateSystemsEnabled) ...[
                TextField(
                  controller: _altSystemController,
                  decoration: InputDecoration(
                    labelText: 'Alternate System (Optional)',
                    hintText: 'e.g. ECEF, Lunar-System',
                    prefixIcon: const Icon(Icons.swap_horiz),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Coordinate Accuracy
              TextField(
                controller: _coordAccController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Coordinate Accuracy (6 decimals max)',
                  hintText: 'e.g. 0.0005',
                  errorText: _coordAccError,
                  prefixIcon: const Icon(Icons.gps_fixed),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Height Accuracy
              TextField(
                controller: _heightAccController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Height Accuracy (6 decimals max)',
                  hintText: 'e.g. 0.001',
                  errorText: _heightAccError,
                  prefixIcon: const Icon(Icons.height),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _clearForm,
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.save),
                    label: const Text('Register'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Registered Reference Frames',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigoAccent,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'Clear Mock DB',
              onPressed: () {
                setState(() {
                  _service.clearLocations();
                  _refreshList();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        _records.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text(
                        'No reference frames saved in mock DB.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final rec = _records[index];
                  final frame = rec.referenceFrame;
                  final system = frame.geodeticSystem;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.indigoAccent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              frame.astronomicalBody.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            system.geodeticDatum,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (frame.alternateSystem != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text('Alternate System: ${frame.alternateSystem}'),
                              ),
                            Row(
                              children: [
                                if (system.coordAccuracy != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.gps_fixed, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('Coord Acc: ${system.coordAccuracy}'),
                                      ],
                                    ),
                                  ),
                                if (system.heightAccuracy != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.height, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('Height Acc: ${system.heightAccuracy}'),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
