import 'package:flutter/material.dart';
import 'models/geo_location.dart';
import 'services/mock_location_service.dart';

void main() {
  runApp(const CogctlUxApp());
}

class CogctlUxApp extends StatefulWidget {
  const CogctlUxApp({super.key});

  @override
  State<CogctlUxApp> createState() => _CogctlUxAppState();
}

class _CogctlUxAppState extends State<CogctlUxApp> {
  // Mode selection state: System, Light, Dark
  ThemeMode _themeMode = ThemeMode.system;

  void _updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // GCP Light Theme Palette
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1A73E8), // Google Cloud Blue
      scaffoldBackgroundColor: const Color(0xFFF8F9FA), // GCP Light Gray Background
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A73E8),
        secondary: Color(0xFF1A73E8),
        surface: Colors.white,
        error: Color(0xFFD93025), // GCP Red Error
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0x1F000000), width: 1), // Thin GCP card border
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFF3C4043)),
        titleMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFF202124), fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A73E8), // Classic GCP Console Header Blue
        foregroundColor: Colors.white,
      ),
    );

    // GCP Dark Theme Palette
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF8AB4F8), // GCP Light Blue for Dark Mode
      scaffoldBackgroundColor: const Color(0xFF202124), // GCP Dark Gray Background
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8AB4F8),
        secondary: Color(0xFF8AB4F8),
        surface: Color(0xFF2D2E30), // GCP Darker card background
        error: Color(0xFFF28B82), // GCP Light Red Error for Dark Mode
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2D2E30),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0x1FFFFFFF), width: 1), // Thin light border for dark mode
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFFE8EAED)),
        titleMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFFF1F3F4), fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D2E30), // GCP Console Header Dark Gray
        foregroundColor: Colors.white,
      ),
    );

    return MaterialApp(
      title: 'Google Cloud Console - GKE Geo-Location Registry',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: ReferenceFrameDashboard(
        currentThemeMode: _themeMode,
        onThemeChanged: _updateThemeMode,
      ),
    );
  }
}

class ReferenceFrameDashboard extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const ReferenceFrameDashboard({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

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

  // Selected Network Domain state
  String _selectedNetworkDomain = 'Terrestrial Fiber (L0-L4)';
  final List<String> _networkDomains = [
    'Terrestrial Fiber (L0-L4)',
    'Mobile / Wireless (L1-L4)',
    'Submarine Cable (Subsea)',
    'Non-Terrestrial Network (NTN)',
    'Deep Space Network (DSN)',
    'Quantum Key Distribution (QKD)',
  ];

  // Validation messages
  String? _generalError;
  String? _bodyError;
  String? _datumError;
  String? _coordAccError;
  String? _heightAccError;

  // List of location records
  List<GeoLocation> _records = [];

  // Drawer / Sidebar state
  bool _isDrawerCollapsed = false;

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
      _selectedNetworkDomain = 'Terrestrial Fiber (L0-L4)';
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

    final location = GeoLocation(
      referenceFrame: referenceFrame,
      networkDomain: _selectedNetworkDomain,
    );

    // 4. Save to Mock DB
    try {
      _service.addLocation(location);
      _clearForm();
      _refreshList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Geographic Reference Frame saved to console database!'),
          backgroundColor: Theme.of(context).primaryColor,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final theme = Theme.of(context);

    return Scaffold(
      // Top Navigation Bar (GCP Console Style)
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isDrawerCollapsed = !_isDrawerCollapsed;
            });
          },
        ),
        title: screenWidth > 950
            ? Row(
                children: [
                  const Text(
                    'Google Cloud',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'GKE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    'RFC 9179 Geo-Location Specs',
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              )
            : Text(
                'RFC 9179 Geo-Location Specs',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
              ),
        actions: [
          // Theme selection dropdown (GCP Console Style theme switcher)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<ThemeMode>(
              value: widget.currentThemeMode,
              dropdownColor: theme.appBarTheme.backgroundColor,
              underline: const SizedBox(),
              icon: const Icon(Icons.palette, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  widget.onThemeChanged(value);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Theme'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light Theme'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark Theme'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar / Left navigation drawer (GCP Console style)
          if (isDesktop) _buildSidebar(theme),

          // Main console container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: isDesktop
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSDNStatusSummary(theme),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _buildFormCard(theme)),
                              const SizedBox(width: 24),
                              Expanded(flex: 6, child: _buildListPane(theme)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSDNStatusSummary(theme),
                          _buildFormCard(theme),
                          const SizedBox(height: 24),
                          _buildListPane(theme),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSDNStatusSummary(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = _records.length;
    int terrestrial = _records.where((r) => r.referenceFrame.astronomicalBody == 'earth' && ((r.networkDomain?.contains('Terrestrial') ?? false) || (r.networkDomain?.contains('Mobile') ?? false))).length;
    int submarine = _records.where((r) => r.networkDomain?.contains('Submarine') ?? false).length;
    int space = _records.where((r) => r.referenceFrame.astronomicalBody != 'earth' || ((r.networkDomain?.contains('Satellite') ?? false) || (r.networkDomain?.contains('Space') ?? false))).length;
    int quantum = _records.where((r) => (r.networkDomain?.contains('Quantum') ?? false) || (r.networkDomain?.contains('QKD') ?? false)).length;

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

  Widget _buildSidebar(ThemeData theme) {
    final collapsedWidth = 72.0;
    final expandedWidth = 240.0;
    final isDark = theme.brightness == Brightness.dark;
    final sidebarBg = isDark ? const Color(0xFF202124) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isDrawerCollapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSidebarItem(
            icon: Icons.dashboard,
            label: 'Console Overview',
            isActive: false,
          ),
          _buildSidebarItem(
            icon: Icons.language,
            label: 'Reference Frames',
            isActive: true,
          ),
          const Divider(height: 16),
          _buildSidebarItem(
            icon: Icons.settings_ethernet,
            label: 'Terrestrial & Mobile (Fiber)',
            isActive: false,
          ),
          _buildSidebarItem(
            icon: Icons.waves,
            label: 'Submarine Networks (Subsea)',
            isActive: false,
          ),
          _buildSidebarItem(
            icon: Icons.satellite_alt,
            label: 'Satellite & NTN Orbiters',
            isActive: false,
          ),
          _buildSidebarItem(
            icon: Icons.rocket_launch,
            label: 'Deep Space Network (DSN)',
            isActive: false,
          ),
          _buildSidebarItem(
            icon: Icons.compare_arrows,
            label: 'Quantum QKD Links',
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    final inactiveColor = theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 20,
            ),
            if (!_isDrawerCollapsed) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    color: isActive ? activeColor : inactiveColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

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
              if (_generalError != null) ...[
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
                          _generalError!,
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
                value: _selectedNetworkDomain,
                decoration: InputDecoration(
                  labelText: 'SDN Network Domain Association',
                  prefixIcon: const Icon(Icons.hub, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onChanged: (String? val) {
                  if (val != null) {
                    setState(() {
                      _selectedNetworkDomain = val;
                    });
                  }
                },
                items: _networkDomains.map((String domain) {
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
                  errorText: _bodyError,
                  prefixIcon: const Icon(Icons.public, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
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
                  prefixIcon: const Icon(Icons.grid_on, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
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
                    prefixIcon: const Icon(Icons.swap_horiz, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
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
                  labelText: 'Coordinate Accuracy (decimal)',
                  hintText: 'e.g. 0.0005',
                  errorText: _coordAccError,
                  prefixIcon: const Icon(Icons.gps_fixed, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Height Accuracy
              TextField(
                controller: _heightAccController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Height Accuracy (decimal)',
                  hintText: 'e.g. 0.001',
                  errorText: _heightAccError,
                  prefixIcon: const Icon(Icons.height, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
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

  Widget _buildListPane(ThemeData theme) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final Widget listContent = _records.isEmpty
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
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final rec = _records[index];
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
                              Icon(Icons.public, color: theme.primaryColor, size: 18),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                setState(() {
                  _service.clearLocations();
                  _refreshList();
                });
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
