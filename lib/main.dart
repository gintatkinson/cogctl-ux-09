import 'package:flutter/material.dart' hide Velocity;
import 'dart:math';
import 'dart:async';
import 'models/geo_location.dart';
import 'services/mock_location_service.dart';
import 'models/counter_gauge.dart';
import 'services/mock_counter_gauge_service.dart';
import 'models/identifiers_references.dart';
import 'services/mock_identifiers_references_service.dart';
import 'models/date_time.dart';
import 'services/mock_date_time_service.dart';
import 'models/time_duration.dart';
import 'services/mock_time_duration_service.dart';
import 'models/address_tag.dart';
import 'services/mock_address_tag_service.dart';
import 'models/inventory_location.dart';
import 'services/mock_inventory_location_service.dart';
import 'models/network_element.dart';
import 'services/mock_network_inventory_service.dart';
import 'models/equipment_rack.dart';
import 'services/mock_equipment_rack_service.dart';


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
      primaryColor: const Color(0xFF3367D6), // Google Cloud Primary Action Blue
      scaffoldBackgroundColor: const Color(0xFFF9F9F9), // GCP Console Canvas Background
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF3367D6),
        secondary: Color(0xFF3367D6),
        surface: Colors.white,
        error: Color(0xFFD93025), // GCP Red Error
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1), // GCP solid light gray border
          borderRadius: BorderRadius.circular(4), // Boxy GCP corners
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFF3C4043)),
        titleMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFF202124), fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF3367D6), // Classic GCP Console Header Blue
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
        surface: Color(0xFF303134), // GCP Darker card background
        error: Color(0xFFF28B82), // GCP Light Red Error for Dark Mode
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF303134),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF3C4043), width: 1), // Dark mode card border
          borderRadius: BorderRadius.circular(4), // Boxy GCP corners
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFFE8EAED)),
        titleMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFFF1F3F4), fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF303134), // GCP Console Header Dark Gray
        foregroundColor: Colors.white,
      ),
    );

    return MaterialApp(
      title: 'xG-AI Cognitive Controller - Geo-Location Registry',
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

  // Choice mode state
  String _coordinateMode = 'Ellipsoidal';

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
  String? _altSystemError;
  String? _datumError;
  String? _coordAccError;
  String? _heightAccError;
  String? _latError;
  String? _lonError;
  String? _heightError;
  String? _xError;
  String? _yError;
  String? _zError;
  String? _vNorthError;
  String? _vEastError;
  String? _vUpError;

  // Dynamic calculated velocity speed/heading
  double? _computedSpeed;
  double? _computedHeading;

  // Expiry / Temporal Validity controllers
  final _timestampController = TextEditingController();
  final _validUntilController = TextEditingController();
  String? _timestampError;
  String? _validUntilError;
  Timer? _expiryUpdateTimer;

  // List of location records
  List<GeoLocation> _records = [];

  // Drawer / Sidebar state
  bool _isDrawerCollapsed = false;

  // Counters & Gauges state
  String _currentScreen = 'reference_frames';
  final MockCounterGaugeService _counterGaugeService = MockCounterGaugeService();
  List<YangCounterGauge> _counterGaugeNodes = [];
  YangCounterGauge? _selectedCounterGaugeNode;
  final _counterGaugeFormKey = GlobalKey<FormState>();
  final _counterGaugeValueController = TextEditingController();
  bool _discontinuityChecked = false;
  String? _counterGaugeValueError;

  // Identifiers & References state
  final MockIdentifiersReferencesService _identifiersService = MockIdentifiersReferencesService();
  List<YangIdentifierReference> _identifierNodes = [];
  YangIdentifierReference? _selectedIdentifierNode;
  final _identifiersFormKey = GlobalKey<FormState>();
  final _identifierValueController = TextEditingController();
  String? _identifierValueError;

  // Date & Time state
  final MockDateTimeService _dateTimeService = MockDateTimeService();
  List<YangDateTimeReference> _dateTimeNodes = [];
  YangDateTimeReference? _selectedDateTimeNode;
  final _dateTimeFormKey = GlobalKey<FormState>();
  final _dateTimeValueController = TextEditingController();
  String? _dateTimeValueError;

  // Time Durations state
  final MockTimeDurationService _timeDurationService = MockTimeDurationService();
  List<YangTimeDurationReference> _timeDurationNodes = [];
  YangTimeDurationReference? _selectedTimeDurationNode;
  final _timeDurationFormKey = GlobalKey<FormState>();
  final _timeDurationValueController = TextEditingController();
  String? _timeDurationValueError;

  // Addresses & Tags state
  final MockAddressTagService _addressTagService = MockAddressTagService();
  List<YangAddressTagReference> _addressTagNodes = [];
  YangAddressTagReference? _selectedAddressTagNode;
  final _addressTagFormKey = GlobalKey<FormState>();
  final _addressTagValueController = TextEditingController();
  String? _addressTagValueError;

  // Hierarchical Locations state
  final MockInventoryLocationService _inventoryLocationService = MockInventoryLocationService();
  List<InventoryLocation> _inventoryLocations = [];
  InventoryLocation? _selectedInventoryLocation;
  final _inventoryLocationFormKey = GlobalKey<FormState>();
  final _locationIdController = TextEditingController();
  final _locationTypeController = TextEditingController();
  final _locationTimestampController = TextEditingController();
  final _locationValidUntilController = TextEditingController();
  final _locationAddressController = TextEditingController();
  final _locationPostalCodeController = TextEditingController();
  final _locationStateController = TextEditingController();
  final _locationCityController = TextEditingController();
  final _locationCountryCodeController = TextEditingController();
  String? _selectedLocationParentId;
  String? _locationFormError;
  String? _locationTimestampError;
  String? _locationValidUntilError;
  String? _locationIdError;
  String? _locationTypeError;
  String? _locationCountryCodeError;
  bool _isEditingLocation = false;

  // Feature 13 state (Direct contained chassis & Network inventory)
  final MockNetworkInventoryService _networkInventoryService = MockNetworkInventoryService();
  List<ContainedChassis> _editingContainedChassis = [];
  final _chassisIdController = TextEditingController();
  String? _chassisNeRef;
  String? _chassisComponentRef;
  String? _chassisError;

  // NE manager helper inputs
  final _newNeIdController = TextEditingController();
  final _newComponentIdController = TextEditingController();
  String? _selectedNeForNewComponent;
  String? _neManagerError;
  bool _isNeManagerExpanded = false;

  // Feature 14 Equipment Racks state
  final MockEquipmentRackService _equipmentRackService = MockEquipmentRackService();
  List<EquipmentRack> _equipmentRacks = [];
  EquipmentRack? _selectedEquipmentRack;
  final _equipmentRackFormKey = GlobalKey<FormState>();
  final _rackIdController = TextEditingController();
  String? _selectedRackClass = 'rack-standard';
  final _rackHeightController = TextEditingController();
  final _rackWidthController = TextEditingController();
  final _rackDepthController = TextEditingController();
  final _rackTimestampController = TextEditingController();
  final _rackValidUntilController = TextEditingController();
  final _rackRowController = TextEditingController();
  final _rackColController = TextEditingController();
  String? _rackFormLocationId;
  String? _selectedPlacementLocationId = 'loc-london-hq';
  String? _rackFormError;
  String? _rackIdError;
  String? _rackHeightError;
  String? _rackWidthError;
  String? _rackDepthError;
  String? _rackTimestampError;
  String? _rackValidUntilError;
  String? _rackRowError;
  String? _rackColError;
  bool _isEditingRack = false;

  @override
  void initState() {
    super.initState();
    _refreshList();
    _refreshCounterGaugeList();
    _refreshIdentifierList();
    _refreshDateTimeList();
    _refreshTimeDurationList();
    _refreshAddressTagList();
    _refreshInventoryLocationList();
    _refreshEquipmentRackList();

    _expiryUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    _timestampController.addListener(() {
      final text = _timestampController.text.trim();
      if (text.isEmpty) {
        if (_timestampError != null) setState(() => _timestampError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseDateTime(text, 'timestamp');
        if (_timestampError != null) setState(() => _timestampError = null);
      } catch (e) {
        setState(() => _timestampError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _validUntilController.addListener(() {
      final text = _validUntilController.text.trim();
      if (text.isEmpty) {
        if (_validUntilError != null) setState(() => _validUntilError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseDateTime(text, 'valid-until');
        if (_validUntilError != null) setState(() => _validUntilError = null);
      } catch (e) {
        setState(() => _validUntilError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _bodyController.addListener(() {
      final text = _bodyController.text.trim();
      if (text.isEmpty) {
        if (_bodyError != null) setState(() => _bodyError = null);
        return;
      }
      try {
        ReferenceFrameValidator.validateAstronomicalBody(ReferenceFrameValidator.normalize(text));
        if (_bodyError != null) setState(() => _bodyError = null);
      } catch (e) {
        setState(() => _bodyError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _altSystemController.addListener(() {
      final text = _altSystemController.text.trim();
      if (text.isEmpty) {
        if (_altSystemError != null) setState(() => _altSystemError = null);
        return;
      }
      try {
        ReferenceFrameValidator.validateAlternateSystem(ReferenceFrameValidator.normalize(text));
        if (_altSystemError != null) setState(() => _altSystemError = null);
      } catch (e) {
        setState(() => _altSystemError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _datumController.addListener(() {
      final text = _datumController.text.trim();
      if (text.isEmpty) {
        if (_datumError != null) setState(() => _datumError = null);
        return;
      }
      try {
        ReferenceFrameValidator.validateGeodeticDatum(ReferenceFrameValidator.normalize(text));
        if (_datumError != null) setState(() => _datumError = null);
      } catch (e) {
        setState(() => _datumError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _coordAccController.addListener(() {
      final text = _coordAccController.text.trim();
      if (text.isEmpty) {
        if (_coordAccError != null) setState(() => _coordAccError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseAccuracy(text);
        if (_coordAccError != null) setState(() => _coordAccError = null);
      } catch (e) {
        setState(() => _coordAccError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _heightAccController.addListener(() {
      final text = _heightAccController.text.trim();
      if (text.isEmpty) {
        if (_heightAccError != null) setState(() => _heightAccError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseAccuracy(text);
        if (_heightAccError != null) setState(() => _heightAccError = null);
      } catch (e) {
        setState(() => _heightAccError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _latController.addListener(() {
      final text = _latController.text.trim();
      if (text.isEmpty) {
        if (_latError != null) setState(() => _latError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseLatitude(text);
        if (_latError != null) setState(() => _latError = null);
      } catch (e) {
        setState(() => _latError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _lonController.addListener(() {
      final text = _lonController.text.trim();
      if (text.isEmpty) {
        if (_lonError != null) setState(() => _lonError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseLongitude(text);
        if (_lonError != null) setState(() => _lonError = null);
      } catch (e) {
        setState(() => _lonError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _heightController.addListener(() {
      final text = _heightController.text.trim();
      if (text.isEmpty) {
        if (_heightError != null) setState(() => _heightError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseHeight(text);
        if (_heightError != null) setState(() => _heightError = null);
      } catch (e) {
        setState(() => _heightError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _xController.addListener(() {
      final text = _xController.text.trim();
      if (text.isEmpty) {
        if (_xError != null) setState(() => _xError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseCartesianCoordinate(text, 'X');
        if (_xError != null) setState(() => _xError = null);
      } catch (e) {
        setState(() => _xError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _yController.addListener(() {
      final text = _yController.text.trim();
      if (text.isEmpty) {
        if (_yError != null) setState(() => _yError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseCartesianCoordinate(text, 'Y');
        if (_yError != null) setState(() => _yError = null);
      } catch (e) {
        setState(() => _yError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _zController.addListener(() {
      final text = _zController.text.trim();
      if (text.isEmpty) {
        if (_zError != null) setState(() => _zError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseCartesianCoordinate(text, 'Z');
        if (_zError != null) setState(() => _zError = null);
      } catch (e) {
        setState(() => _zError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });

    _vNorthController.addListener(() {
      final text = _vNorthController.text.trim();
      if (text.isEmpty) {
        if (_vNorthError != null) setState(() => _vNorthError = null);
        _recalculateVelocity();
        return;
      }
      try {
        ReferenceFrameValidator.parseVelocityComponent(text, 'v-north');
        if (_vNorthError != null) setState(() => _vNorthError = null);
      } catch (e) {
        setState(() => _vNorthError = e.toString().replaceFirst('FormatException: ', ''));
      }
      _recalculateVelocity();
    });

    _vEastController.addListener(() {
      final text = _vEastController.text.trim();
      if (text.isEmpty) {
        if (_vEastError != null) setState(() => _vEastError = null);
        _recalculateVelocity();
        return;
      }
      try {
        ReferenceFrameValidator.parseVelocityComponent(text, 'v-east');
        if (_vEastError != null) setState(() => _vEastError = null);
      } catch (e) {
        setState(() => _vEastError = e.toString().replaceFirst('FormatException: ', ''));
      }
      _recalculateVelocity();
    });

    _vUpController.addListener(() {
      final text = _vUpController.text.trim();
      if (text.isEmpty) {
        if (_vUpError != null) setState(() => _vUpError = null);
        return;
      }
      try {
        ReferenceFrameValidator.parseVelocityComponent(text, 'v-up');
        if (_vUpError != null) setState(() => _vUpError = null);
      } catch (e) {
        setState(() => _vUpError = e.toString().replaceFirst('FormatException: ', ''));
      }
    });
  }

  void _recalculateVelocity() {
    final vNorthStr = _vNorthController.text.trim();
    final vEastStr = _vEastController.text.trim();
    if (vNorthStr.isEmpty && vEastStr.isEmpty) {
      setState(() {
        _computedSpeed = null;
        _computedHeading = null;
      });
      return;
    }
    final vNorth = double.tryParse(vNorthStr);
    final vEast = double.tryParse(vEastStr);
    
    if (vNorth == null || vEast == null) {
      setState(() {
        _computedSpeed = null;
        _computedHeading = null;
      });
      return;
    }
    
    final speed = sqrt(vNorth * vNorth + vEast * vEast);
    double headingRad = atan2(vEast, vNorth);
    double headingDeg = headingRad * 180 / pi;
    if (headingDeg < 0) {
      headingDeg += 360.0;
    }
    setState(() {
      _computedSpeed = speed;
      _computedHeading = headingDeg;
    });
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
    _counterGaugeValueController.dispose();
    _identifierValueController.dispose();
    _rackIdController.dispose();
    _rackHeightController.dispose();
    _rackWidthController.dispose();
    _rackDepthController.dispose();
    _rackTimestampController.dispose();
    _rackValidUntilController.dispose();
    _rackRowController.dispose();
    _rackColController.dispose();
    _expiryUpdateTimer?.cancel();
    super.dispose();
  }

  void _refreshCounterGaugeList() {
    setState(() {
      _counterGaugeNodes = _counterGaugeService.getNodes();
      if (_selectedCounterGaugeNode != null) {
        final existingIndex = _counterGaugeNodes.indexWhere((n) => n.id == _selectedCounterGaugeNode!.id);
        if (existingIndex != -1) {
          _selectedCounterGaugeNode = _counterGaugeNodes[existingIndex];
        } else if (_counterGaugeNodes.isNotEmpty) {
          _selectedCounterGaugeNode = _counterGaugeNodes.first;
        }
      } else if (_counterGaugeNodes.isNotEmpty) {
        _selectedCounterGaugeNode = _counterGaugeNodes.first;
      }
    });
  }

  void _submitCounterGaugeUpdate() {
    if (_selectedCounterGaugeNode == null) return;
    
    final text = _counterGaugeValueController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _counterGaugeValueError = 'Value cannot be empty';
      });
      return;
    }

    final newValue = BigInt.tryParse(text);
    if (newValue == null || newValue < BigInt.zero) {
      setState(() {
        _counterGaugeValueError = 'Please enter a valid non-negative integer';
      });
      return;
    }

    try {
      _counterGaugeService.updateNodeValue(
        _selectedCounterGaugeNode!.id,
        newValue,
        discontinuity: _discontinuityChecked,
      );
      
      setState(() {
        _counterGaugeValueError = null;
        _discontinuityChecked = false;
      });

      _refreshCounterGaugeList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated ${_selectedCounterGaugeNode!.name} to $newValue'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _counterGaugeValueError = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  void _refreshIdentifierList() {
    setState(() {
      _identifierNodes = _identifiersService.getNodes();
      if (_selectedIdentifierNode != null) {
        final existingIndex = _identifierNodes.indexWhere((n) => n.id == _selectedIdentifierNode!.id);
        if (existingIndex != -1) {
          _selectedIdentifierNode = _identifierNodes[existingIndex];
        } else if (_identifierNodes.isNotEmpty) {
          _selectedIdentifierNode = _identifierNodes.first;
        }
      } else if (_identifierNodes.isNotEmpty) {
        _selectedIdentifierNode = _identifierNodes.first;
        _identifierValueController.text = _selectedIdentifierNode!.value;
      }
    });
  }

  void _submitIdentifierUpdate() {
    if (_selectedIdentifierNode == null) return;
    
    final text = _identifierValueController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _identifierValueError = 'Value cannot be empty';
      });
      return;
    }

    try {
      _identifiersService.updateNodeValue(
        _selectedIdentifierNode!.id,
        text,
      );
      
      setState(() {
        _identifierValueError = null;
      });

      _refreshIdentifierList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated ${_selectedIdentifierNode!.name} to $text'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _identifierValueError = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  void _refreshDateTimeList() {
    setState(() {
      _dateTimeNodes = _dateTimeService.getNodes();
      if (_selectedDateTimeNode != null) {
        final existingIndex = _dateTimeNodes.indexWhere((n) => n.id == _selectedDateTimeNode!.id);
        if (existingIndex != -1) {
          _selectedDateTimeNode = _dateTimeNodes[existingIndex];
        } else if (_dateTimeNodes.isNotEmpty) {
          _selectedDateTimeNode = _dateTimeNodes.first;
        }
      } else if (_dateTimeNodes.isNotEmpty) {
        _selectedDateTimeNode = _dateTimeNodes.first;
        _dateTimeValueController.text = _selectedDateTimeNode!.value;
      }
    });
  }

  void _submitDateTimeUpdate() {
    if (_selectedDateTimeNode == null) return;
    
    final text = _dateTimeValueController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _dateTimeValueError = 'Value cannot be empty';
      });
      return;
    }

    try {
      _dateTimeService.updateNodeValue(
        _selectedDateTimeNode!.id,
        text,
      );
      
      setState(() {
        _dateTimeValueError = null;
      });

      _refreshDateTimeList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated ${_selectedDateTimeNode!.name} to $text'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _dateTimeValueError = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  void _setToCurrentTime() {
    if (_selectedDateTimeNode == null) return;
    
    final now = DateTime.now().toUtc();
    String formattedValue = '';
    
    switch (_selectedDateTimeNode!.type) {
      case YangDateTimeType.dateAndTime:
        formattedValue = '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}T'
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}:'
            '${now.second.toString().padLeft(2, '0')}Z';
        break;
      case YangDateTimeType.date:
        formattedValue = '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}Z';
        break;
      case YangDateTimeType.dateNoZone:
        formattedValue = '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
        break;
      case YangDateTimeType.time:
        formattedValue = '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}:'
            '${now.second.toString().padLeft(2, '0')}Z';
        break;
      case YangDateTimeType.timeNoZone:
        formattedValue = '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}:'
            '${now.second.toString().padLeft(2, '0')}';
        break;
    }
    
    setState(() {
      _dateTimeValueController.text = formattedValue;
      _dateTimeValueError = null;
    });
  }

  void _refreshTimeDurationList() {
    setState(() {
      _timeDurationNodes = _timeDurationService.getNodes();
      if (_selectedTimeDurationNode != null) {
        final existingIndex = _timeDurationNodes.indexWhere((n) => n.id == _selectedTimeDurationNode!.id);
        if (existingIndex != -1) {
          _selectedTimeDurationNode = _timeDurationNodes[existingIndex];
        } else if (_timeDurationNodes.isNotEmpty) {
          _selectedTimeDurationNode = _timeDurationNodes.first;
        }
      } else if (_timeDurationNodes.isNotEmpty) {
        _selectedTimeDurationNode = _timeDurationNodes.first;
        _timeDurationValueController.text = _selectedTimeDurationNode!.value;
      }
    });
  }

  void _submitTimeDurationUpdate() {
    if (_selectedTimeDurationNode == null) return;
    
    final text = _timeDurationValueController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _timeDurationValueError = 'Value cannot be empty';
      });
      return;
    }

    try {
      _timeDurationService.updateNodeValue(
        _selectedTimeDurationNode!.id,
        text,
      );
      
      setState(() {
        _timeDurationValueError = null;
      });

      _refreshTimeDurationList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated ${_selectedTimeDurationNode!.name} to $text'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _timeDurationValueError = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  void _simulateWrapAround() {
    if (_selectedTimeDurationNode == null) return;
    if (_selectedTimeDurationNode!.type != YangTimeDurationType.timeticks) return;
    
    _timeDurationValueController.text = '0';
    _submitTimeDurationUpdate();
  }

  void _refreshAddressTagList() {
    setState(() {
      _addressTagNodes = _addressTagService.getNodes();
      if (_selectedAddressTagNode != null) {
        final existingIndex = _addressTagNodes.indexWhere((n) => n.id == _selectedAddressTagNode!.id);
        if (existingIndex != -1) {
          _selectedAddressTagNode = _addressTagNodes[existingIndex];
        } else if (_addressTagNodes.isNotEmpty) {
          _selectedAddressTagNode = _addressTagNodes.first;
        }
      } else if (_addressTagNodes.isNotEmpty) {
        _selectedAddressTagNode = _addressTagNodes.first;
        _addressTagValueController.text = _selectedAddressTagNode!.value;
      }
    });
  }

  void _submitAddressTagUpdate() {
    if (_selectedAddressTagNode == null) return;
    
    final text = _addressTagValueController.text.trim();
    if (text.isEmpty && _selectedAddressTagNode!.type != YangAddressTagType.physAddress && _selectedAddressTagNode!.type != YangAddressTagType.hexString) {
      setState(() {
        _addressTagValueError = 'Value cannot be empty';
      });
      return;
    }

    try {
      _addressTagService.updateNodeValue(
        _selectedAddressTagNode!.id,
        text,
      );
      
      setState(() {
        _addressTagValueError = null;
      });

      _refreshAddressTagList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated ${_selectedAddressTagNode!.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _addressTagValueError = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  void _clearForm() {
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
    _dateTimeValueController.clear();
    _addressTagValueController.clear();
    _locationIdController.clear();
    _locationTypeController.clear();
    _locationTimestampController.clear();
    _locationValidUntilController.clear();
    _locationAddressController.clear();
    _locationPostalCodeController.clear();
    _locationStateController.clear();
    _locationCityController.clear();
    _locationCountryCodeController.clear();
    setState(() {
      _coordinateMode = 'Ellipsoidal';
      _selectedNetworkDomain = 'Terrestrial Fiber (L0-L4)';
      _generalError = null;
      _bodyError = null;
      _altSystemError = null;
      _datumError = null;
      _coordAccError = null;
      _heightAccError = null;
      _latError = null;
      _lonError = null;
      _heightError = null;
      _xError = null;
      _yError = null;
      _zError = null;
      _vNorthError = null;
      _vEastError = null;
      _vUpError = null;
      _timestampError = null;
      _validUntilError = null;
      _computedSpeed = null;
      _computedHeading = null;
      _dateTimeValueError = null;
      _addressTagValueError = null;
      _selectedLocationParentId = null;
      _locationFormError = null;
      _locationTimestampError = null;
      _locationValidUntilError = null;
      _locationIdError = null;
      _locationTypeError = null;
      _locationCountryCodeError = null;
      _isEditingLocation = false;
      _selectedInventoryLocation = null;
    });
  }

  void _submitForm() {
    setState(() {
      _generalError = null;
      _bodyError = null;
      _altSystemError = null;
      _datumError = null;
      _coordAccError = null;
      _heightAccError = null;
      _latError = null;
      _lonError = null;
      _heightError = null;
      _xError = null;
      _yError = null;
      _zError = null;
      _vNorthError = null;
      _vEastError = null;
      _vUpError = null;
      _timestampError = null;
      _validUntilError = null;
    });

    final rawBody = _bodyController.text.trim();
    final rawDatum = _datumController.text.trim();
    final rawAlt = _altSystemController.text.trim();
    final rawCoord = _coordAccController.text.trim();
    final rawHeightAcc = _heightAccController.text.trim();
    final rawLat = _latController.text.trim();
    final rawLon = _lonController.text.trim();
    final rawHeightVal = _heightController.text.trim();
    final rawX = _xController.text.trim();
    final rawY = _yController.text.trim();
    final rawZ = _zController.text.trim();

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
    // Validate Alternate System pattern
    String? alternateSystem = _alternateSystemsEnabled && rawAlt.isNotEmpty 
        ? ReferenceFrameValidator.normalize(rawAlt) 
        : null;

    if (alternateSystem != null) {
      try {
        ReferenceFrameValidator.validateAlternateSystem(alternateSystem);
      } catch (e) {
        setState(() {
          _altSystemError = e.toString().replaceFirst('FormatException: ', '');
        });
        hasError = true;
      }
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
    if (rawHeightAcc.isNotEmpty) {
      try {
        heightAccuracy = ReferenceFrameValidator.parseAccuracy(rawHeightAcc);
      } catch (e) {
        setState(() {
          _heightAccError = e.toString().replaceFirst('FormatException: ', '');
        });
        hasError = true;
      }
    }

    double? latitude;
    double? longitude;
    double? height;
    double? xVal;
    double? yVal;
    double? zVal;

    if (_coordinateMode == 'Ellipsoidal') {
      // New validation for Ellipsoidal Coordinates
      final bool anyCoordProvided = rawLat.isNotEmpty || rawLon.isNotEmpty || rawHeightVal.isNotEmpty;
      if (anyCoordProvided) {
        if (rawLat.isEmpty) {
          setState(() {
            _latError = 'Latitude is required when longitude/height is specified';
          });
          hasError = true;
        }
        if (rawLon.isEmpty) {
          setState(() {
            _lonError = 'Longitude is required when latitude/height is specified';
          });
          hasError = true;
        }
      }

      if (rawLat.isNotEmpty) {
        try {
          latitude = ReferenceFrameValidator.parseLatitude(rawLat);
        } catch (e) {
          setState(() {
            _latError = e.toString().replaceFirst('FormatException: ', '');
          });
          hasError = true;
        }
      }

      if (rawLon.isNotEmpty) {
        try {
          longitude = ReferenceFrameValidator.parseLongitude(rawLon);
        } catch (e) {
          setState(() {
            _lonError = e.toString().replaceFirst('FormatException: ', '');
          });
          hasError = true;
        }
      }

      if (rawHeightVal.isNotEmpty) {
        try {
          height = ReferenceFrameValidator.parseHeight(rawHeightVal);
        } catch (e) {
          setState(() {
            _heightError = e.toString().replaceFirst('FormatException: ', '');
          });
          hasError = true;
        }
      }
    } else {
      // Cartesian Mode
      if (rawX.isEmpty || rawY.isEmpty || rawZ.isEmpty) {
        setState(() {
          _generalError = 'All X, Y, Z coordinates are required in Cartesian mode';
          if (rawX.isEmpty) _xError = 'X coordinate is required in Cartesian mode';
          if (rawY.isEmpty) _yError = 'Y coordinate is required in Cartesian mode';
          if (rawZ.isEmpty) _zError = 'Z coordinate is required in Cartesian mode';
        });
        hasError = true;
      }

      if (rawX.isNotEmpty) {
        try {
          xVal = ReferenceFrameValidator.parseCartesianCoordinate(rawX, 'X');
        } catch (e) {
          setState(() {
            _xError = e.toString().replaceFirst('FormatException: ', '');
          });
          hasError = true;
        }
      }

      if (rawY.isNotEmpty) {
        try {
          yVal = ReferenceFrameValidator.parseCartesianCoordinate(rawY, 'Y');
        } catch (e) {
          setState(() {
            _yError = e.toString().replaceFirst('FormatException: ', '');
          });
          hasError = true;
        }
      }

      if (rawZ.isNotEmpty) {
        try {
          zVal = ReferenceFrameValidator.parseCartesianCoordinate(rawZ, 'Z');
        } catch (e) {
          setState(() {
            _zError = e.toString().replaceFirst('FormatException: ', '');
          });
          hasError = true;
        }
      }
    }

    double? vNorth;
    double? vEast;
    double? vUp;

    final rawVNorth = _vNorthController.text.trim();
    final rawVEast = _vEastController.text.trim();
    final rawVUp = _vUpController.text.trim();

    if (rawVNorth.isNotEmpty) {
      try {
        vNorth = ReferenceFrameValidator.parseVelocityComponent(rawVNorth, 'v-north');
      } catch (e) {
        setState(() {
          _vNorthError = e.toString().replaceFirst('FormatException: ', '');
        });
        hasError = true;
      }
    }
    if (rawVEast.isNotEmpty) {
      try {
        vEast = ReferenceFrameValidator.parseVelocityComponent(rawVEast, 'v-east');
      } catch (e) {
        setState(() {
          _vEastError = e.toString().replaceFirst('FormatException: ', '');
        });
        hasError = true;
      }
    }
    if (rawVUp.isNotEmpty) {
      try {
        vUp = ReferenceFrameValidator.parseVelocityComponent(rawVUp, 'v-up');
      } catch (e) {
        setState(() {
          _vUpError = e.toString().replaceFirst('FormatException: ', '');
        });
        hasError = true;
      }
    }

    final rawTimestamp = _timestampController.text.trim();
    final rawValidUntil = _validUntilController.text.trim();

    DateTime? timestampVal;
    if (rawTimestamp.isNotEmpty) {
      try {
        timestampVal = ReferenceFrameValidator.parseDateTime(rawTimestamp, 'timestamp');
      } catch (e) {
        setState(() {
          _timestampError = e.toString().replaceFirst('FormatException: ', '');
        });
        hasError = true;
      }
    }

    DateTime? validUntilVal;
    if (rawValidUntil.isNotEmpty) {
      try {
        validUntilVal = ReferenceFrameValidator.parseDateTime(rawValidUntil, 'valid-until');
      } catch (e) {
        setState(() {
          _validUntilError = e.toString().replaceFirst('FormatException: ', '');
        });
        hasError = true;
      }
    }

    if (timestampVal != null && validUntilVal != null) {
      try {
        ReferenceFrameValidator.validateTemporalValidity(timestampVal, validUntilVal);
      } catch (e) {
        setState(() {
          _generalError = e.toString().replaceFirst('FormatException: ', '');
          _validUntilError = e.toString().replaceFirst('FormatException: ', '');
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
      alternateSystem: alternateSystem,
      geodeticSystem: geodeticSystem,
    );

    LocationCoordinate? locationCoord;
    if (_coordinateMode == 'Ellipsoidal') {
      if (latitude != null && longitude != null) {
        locationCoord = EllipsoidCoordinate(
          latitude: latitude,
          longitude: longitude,
          height: height,
        );
      }
    } else {
      if (xVal != null && yVal != null && zVal != null) {
        locationCoord = CartesianCoordinate(
          x: xVal,
          y: yVal,
          z: zVal,
        );
      }
    }

    Velocity? velocityObj;
    if (vNorth != null || vEast != null || vUp != null) {
      velocityObj = Velocity(
        vNorth: vNorth,
        vEast: vEast,
        vUp: vUp,
      );
    }

    final location = GeoLocation(
      referenceFrame: referenceFrame,
      networkDomain: _selectedNetworkDomain,
      location: locationCoord,
      velocity: velocityObj,
      timestamp: timestampVal,
      validUntil: validUntilVal,
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
        leading: isDesktop
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  setState(() {
                    _isDrawerCollapsed = !_isDrawerCollapsed;
                  });
                },
              )
            : null,
        title: screenWidth > 950
            ? Row(
                children: [
                  const Text(
                    'xG-AI',
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
                      'Cognitive Controller',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    _currentScreen == 'reference_frames'
                        ? 'RFC 9179 Geo-Location Specs'
                        : (_currentScreen == 'counters_gauges'
                            ? 'RFC 9911 Counters & Gauges'
                            : (_currentScreen == 'identifiers_references'
                                ? 'RFC 9911 Identifiers & Refs'
                                : (_currentScreen == 'date_time'
                                    ? 'RFC 9911 Date & Time Types'
                                    : (_currentScreen == 'time_durations'
                                        ? 'RFC 9911 Time Durations'
                                        : (_currentScreen == 'addresses_tags'
                                            ? 'RFC 9911 Addresses & Tags'
                                            : (_currentScreen == 'equipment_racks'
                                                ? 'Equipment Racks Specs'
                                                : 'IETF NI-Location Hierarchies')))))),
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              )
            : Text(
                _currentScreen == 'reference_frames'
                    ? 'RFC 9179 Geo-Location Specs'
                    : (_currentScreen == 'counters_gauges'
                        ? 'RFC 9911 Counters & Gauges'
                        : (_currentScreen == 'identifiers_references'
                            ? 'RFC 9911 Identifiers & Refs'
                            : (_currentScreen == 'date_time'
                                ? 'RFC 9911 Date & Time Types'
                                : (_currentScreen == 'time_durations'
                                    ? 'RFC 9911 Time Durations'
                                    : (_currentScreen == 'addresses_tags'
                                        ? 'RFC 9911 Addresses & Tags'
                                        : (_currentScreen == 'equipment_racks'
                                            ? 'Equipment Racks Specs'
                                            : 'IETF NI-Location Hierarchies')))))) ,
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
      drawer: isDesktop
          ? null
          : Drawer(
              child: Container(
                color: theme.brightness == Brightness.dark ? const Color(0xFF202124) : Colors.white,
                child: _buildSidebar(theme),
              ),
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
              child: _currentScreen == 'reference_frames'
                  ? (isDesktop
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
                        ))
                  : (_currentScreen == 'counters_gauges'
                      ? (isDesktop
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCountersGaugesHeader(theme),
                                const SizedBox(height: 12),
                                _buildCountersGaugesSummary(theme),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 5, child: _buildCounterGaugeFormCard(theme)),
                                      const SizedBox(width: 24),
                                      Expanded(flex: 6, child: _buildCounterGaugeListPane(theme)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCountersGaugesHeader(theme),
                                  const SizedBox(height: 12),
                                  _buildCountersGaugesSummary(theme),
                                  const SizedBox(height: 24),
                                  _buildCounterGaugeFormCard(theme),
                                  const SizedBox(height: 24),
                                  _buildCounterGaugeListPane(theme),
                                ],
                              ),
                            ))
                      : (_currentScreen == 'identifiers_references'
                          ? (isDesktop
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildIdentifiersReferencesHeader(theme),
                                    const SizedBox(height: 12),
                                    _buildIdentifiersReferencesSummary(theme),
                                    const SizedBox(height: 24),
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(flex: 5, child: _buildIdentifierFormCard(theme)),
                                          const SizedBox(width: 24),
                                          Expanded(flex: 6, child: _buildIdentifierListPane(theme)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildIdentifiersReferencesHeader(theme),
                                      const SizedBox(height: 12),
                                      _buildIdentifiersReferencesSummary(theme),
                                      const SizedBox(height: 24),
                                      _buildIdentifierFormCard(theme),
                                      const SizedBox(height: 24),
                                      _buildIdentifierListPane(theme),
                                    ],
                                  ),
                                ))
                          : (_currentScreen == 'date_time'
                              ? (isDesktop
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDateTimeHeader(theme),
                                        const SizedBox(height: 12),
                                        _buildDateTimeSummary(theme),
                                        const SizedBox(height: 24),
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(flex: 5, child: _buildDateTimeFormCard(theme)),
                                              const SizedBox(width: 24),
                                              Expanded(flex: 6, child: _buildDateTimeListPane(theme)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildDateTimeHeader(theme),
                                          const SizedBox(height: 12),
                                          _buildDateTimeSummary(theme),
                                          const SizedBox(height: 24),
                                          _buildDateTimeFormCard(theme),
                                          const SizedBox(height: 24),
                                          _buildDateTimeListPane(theme),
                                        ],
                                      ),
                                    ))
                              : (_currentScreen == 'time_durations'
                                  ? (isDesktop
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildTimeDurationHeader(theme),
                                            const SizedBox(height: 12),
                                            _buildTimeDurationSummary(theme),
                                            const SizedBox(height: 24),
                                            Expanded(
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(flex: 5, child: _buildTimeDurationFormCard(theme)),
                                                  const SizedBox(width: 24),
                                                  Expanded(flex: 6, child: _buildTimeDurationListPane(theme)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildTimeDurationHeader(theme),
                                              const SizedBox(height: 12),
                                              _buildTimeDurationSummary(theme),
                                              const SizedBox(height: 24),
                                              _buildTimeDurationFormCard(theme),
                                              const SizedBox(height: 24),
                                              _buildTimeDurationListPane(theme),
                                            ],
                                          ),
                                        ))
                                  : (_currentScreen == 'addresses_tags'
                                      ? (isDesktop
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildAddressTagHeader(theme),
                                                const SizedBox(height: 12),
                                                _buildAddressTagSummary(theme),
                                                const SizedBox(height: 24),
                                                Expanded(
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(flex: 5, child: _buildAddressTagFormCard(theme)),
                                                      const SizedBox(width: 24),
                                                      Expanded(flex: 6, child: _buildAddressTagListPane(theme)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildAddressTagHeader(theme),
                                                  const SizedBox(height: 12),
                                                  _buildAddressTagSummary(theme),
                                                  const SizedBox(height: 24),
                                                  _buildAddressTagFormCard(theme),
                                                  const SizedBox(height: 24),
                                                  _buildAddressTagListPane(theme),
                                                ],
                                              ),
                                            ))
                                      : (_currentScreen == 'equipment_racks'
                                          ? (isDesktop
                                              ? SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildEquipmentRacksHeader(theme),
                                                      const SizedBox(height: 12),
                                                      _buildEquipmentRacksSummary(theme),
                                                      const SizedBox(height: 24),
                                                      _buildFacilityFloorPlanCard(theme),
                                                      const SizedBox(height: 24),
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(flex: 5, child: _buildEquipmentRackFormCard(theme)),
                                                          const SizedBox(width: 24),
                                                          Expanded(flex: 6, child: _buildEquipmentRackListPane(theme)),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildEquipmentRacksHeader(theme),
                                                      const SizedBox(height: 12),
                                                      _buildEquipmentRacksSummary(theme),
                                                      const SizedBox(height: 24),
                                                      _buildFacilityFloorPlanCard(theme),
                                                      const SizedBox(height: 24),
                                                      _buildEquipmentRackFormCard(theme),
                                                      const SizedBox(height: 24),
                                                      _buildEquipmentRackListPane(theme),
                                                    ],
                                                  ),
                                                ))
                                          : (isDesktop
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    _buildInventoryLocationHeader(theme),
                                                    const SizedBox(height: 12),
                                                    _buildInventoryLocationSummary(theme),
                                                    const SizedBox(height: 16),
                                                    _buildNetworkInventoryManager(theme),
                                                    const SizedBox(height: 16),
                                                    Expanded(
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(flex: 5, child: _buildInventoryLocationFormCard(theme)),
                                                          const SizedBox(width: 24),
                                                          Expanded(flex: 6, child: _buildInventoryLocationListPane(theme)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildInventoryLocationHeader(theme),
                                                      const SizedBox(height: 12),
                                                      _buildInventoryLocationSummary(theme),
                                                      const SizedBox(height: 16),
                                                      _buildNetworkInventoryManager(theme),
                                                      const SizedBox(height: 16),
                                                      _buildInventoryLocationFormCard(theme),
                                                      const SizedBox(height: 24),
                                                      _buildInventoryLocationListPane(theme),
                                                    ],
                                                  ),
                                                )))))))),
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
    final isDesktop = MediaQuery.of(context).size.width > 900;

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
            onTap: () {},
          ),
          _buildSidebarItem(
            icon: Icons.language,
            label: 'Reference Frames',
            isActive: _currentScreen == 'reference_frames',
            onTap: () {
              setState(() {
                _currentScreen = 'reference_frames';
              });
              if (!isDesktop) {
                Navigator.of(context).pop();
              }
            },
          ),
          _buildSidebarItem(
            icon: Icons.analytics,
            label: 'Counters & Gauges',
            isActive: _currentScreen == 'counters_gauges',
            onTap: () {
              setState(() {
                _currentScreen = 'counters_gauges';
              });
              if (!isDesktop) {
                Navigator.of(context).pop();
              }
            },
          ),
          _buildSidebarItem(
            icon: Icons.fingerprint,
            label: 'Identifiers & Refs',
            isActive: _currentScreen == 'identifiers_references',
            onTap: () {
              setState(() {
                _currentScreen = 'identifiers_references';
              });
              if (!isDesktop) {
                Navigator.of(context).pop();
              }
            },
          ),
          _buildSidebarItem(
            icon: Icons.calendar_today,
            label: 'Date & Time Types',
            isActive: _currentScreen == 'date_time',
            onTap: () {
              setState(() {
                _currentScreen = 'date_time';
              });
              if (!isDesktop) {
                Navigator.of(context).pop();
              }
            },
          ),
          _buildSidebarItem(
            icon: Icons.hourglass_top,
            label: 'Time Durations',
            isActive: _currentScreen == 'time_durations',
            onTap: () {
              setState(() {
                _currentScreen = 'time_durations';
              });
              if (!isDesktop) {
                Navigator.of(context).pop();
              }
            },
          ),
          _buildSidebarItem(
            icon: Icons.tag,
            label: 'Addresses & Tags',
            isActive: _currentScreen == 'addresses_tags',
            onTap: () {
              setState(() {
                _currentScreen = 'addresses_tags';
              });
              if (!isDesktop) {
                Navigator.of(context).pop();
              }
            },
          ),
          _buildSidebarItem(
            icon: Icons.account_tree,
            label: 'Inventory Locations',
            isActive: _currentScreen == 'inventory_locations',
            onTap: () {
              setState(() {
                _currentScreen = 'inventory_locations';
              });
              if (!isDesktop) {
                Navigator.of(context).pop();
              }
            },
          ),
          _buildSidebarItem(
            icon: Icons.grid_view,
            label: 'Equipment Racks',
            isActive: _currentScreen == 'equipment_racks',
            onTap: () {
              setState(() {
                _currentScreen = 'equipment_racks';
              });
              if (!isDesktop) {
                Navigator.of(context).pop();
              }
            },
          ),
          const Divider(height: 16),
          _buildSidebarItem(
            icon: Icons.settings_ethernet,
            label: 'Terrestrial & Mobile (Fiber)',
            isActive: false,
            onTap: () {},
          ),
          _buildSidebarItem(
            icon: Icons.waves,
            label: 'Submarine Networks (Subsea)',
            isActive: false,
            onTap: () {},
          ),
          _buildSidebarItem(
            icon: Icons.satellite_alt,
            label: 'Satellite & NTN Orbiters',
            isActive: false,
            onTap: () {},
          ),
          _buildSidebarItem(
            icon: Icons.rocket_launch,
            label: 'Deep Space Network (DSN)',
            isActive: false,
            onTap: () {},
          ),
          _buildSidebarItem(
            icon: Icons.compare_arrows,
            label: 'Quantum QKD Links',
            isActive: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    final inactiveColor = theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: onTap,
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
                initialValue: _selectedNetworkDomain,
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
                    errorText: _altSystemError,
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
                      _coordinateMode == 'Ellipsoidal',
                      _coordinateMode == 'Cartesian',
                    ],
                    onPressed: (index) {
                      setState(() {
                        _coordinateMode = index == 0 ? 'Ellipsoidal' : 'Cartesian';
                        _latError = null;
                        _lonError = null;
                        _heightError = null;
                        _xError = null;
                        _yError = null;
                        _zError = null;
                      });
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

              if (_coordinateMode == 'Ellipsoidal') ...[
                // Latitude
                TextField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Latitude (decimal degrees)',
                    hintText: 'e.g. 37.7749',
                    errorText: _latError,
                    prefixIcon: const Icon(Icons.explore, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Longitude
                TextField(
                  controller: _lonController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Longitude (decimal degrees)',
                    hintText: 'e.g. -122.4194',
                    errorText: _lonError,
                    prefixIcon: const Icon(Icons.explore, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Height
                TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Height (meters, optional)',
                    hintText: 'e.g. 10.5',
                    errorText: _heightError,
                    prefixIcon: const Icon(Icons.vertical_align_top, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ] else ...[
                // X coordinate
                TextField(
                  controller: _xController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'X Coordinate (meters)',
                    hintText: 'e.g. 6378137.123456',
                    errorText: _xError,
                    prefixIcon: const Icon(Icons.gps_fixed, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Y coordinate
                TextField(
                  controller: _yController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Y Coordinate (meters)',
                    hintText: 'e.g. 0.0',
                    errorText: _yError,
                    prefixIcon: const Icon(Icons.gps_fixed, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Z coordinate
                TextField(
                  controller: _zController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Z Coordinate (meters)',
                    hintText: 'e.g. 0.0',
                    errorText: _zError,
                    prefixIcon: const Icon(Icons.gps_fixed, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
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
                  errorText: _vNorthError,
                  prefixIcon: const Icon(Icons.north, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // v-east
              TextField(
                controller: _vEastController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: 'Eastward Velocity (v-east, m/s)',
                  hintText: 'e.g. 5.5',
                  errorText: _vEastError,
                  prefixIcon: const Icon(Icons.east, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // v-up
              TextField(
                controller: _vUpController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: 'Upward Velocity (v-up, m/s)',
                  hintText: 'e.g. 0.1',
                  errorText: _vUpError,
                  prefixIcon: const Icon(Icons.arrow_upward, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Computed Speed & Heading Display
              if (_computedSpeed != null && _computedHeading != null) ...[
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
                          'Live Computed Horizontal Speed: ${_computedSpeed!.toStringAsFixed(2)} m/s (${(_computedSpeed! * 3.6).toStringAsFixed(2)} km/h)  |  Heading: ${_computedHeading!.toStringAsFixed(2)}°',
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
                        errorText: _timestampError,
                        prefixIcon: const Icon(Icons.access_time, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
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
                        errorText: _validUntilError,
                        prefixIcon: const Icon(Icons.timer_off, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
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
                      final base = DateTime.tryParse(_timestampController.text.trim()) ?? DateTime.now();
                      setState(() {
                        _validUntilController.text = base.add(const Duration(hours: 1)).toUtc().toIso8601String();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('+1 Hour'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final base = DateTime.tryParse(_timestampController.text.trim()) ?? DateTime.now();
                      setState(() {
                        _validUntilController.text = base.add(const Duration(days: 1)).toUtc().toIso8601String();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('+1 Day'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final base = DateTime.tryParse(_timestampController.text.trim()) ?? DateTime.now();
                      setState(() {
                        _validUntilController.text = base.add(const Duration(days: 7)).toUtc().toIso8601String();
                      });
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
                          Builder(
                            builder: (context) {
                              final now = DateTime.now();
                              final validUntil = rec.validUntil;
                              String badgeText = 'PERSISTENT';
                              Color badgeColor = Colors.grey;

                              if (validUntil != null) {
                                if (validUntil.isBefore(now)) {
                                  badgeText = 'EXPIRED';
                                  badgeColor = Colors.orange;
                                } else {
                                  badgeText = 'ACTIVE';
                                  badgeColor = Colors.green;
                                }
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
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

  Widget _buildCountersGaugesHeader(ThemeData theme) {
    return Row(
      children: [
        Text(
          'Counters & Gauges Dashboard',
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
            color: Colors.blue.withValues(alpha: 0.15),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'RFC 9911 / ietf-yang-types',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountersGaugesSummary(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = _counterGaugeNodes.length;
    int counters = _counterGaugeNodes.where((n) => n.isCounter).length;
    int gauges = _counterGaugeNodes.where((n) => n.isGauge).length;
    int zeroBased = _counterGaugeNodes.where((n) => n.isZeroBased).length;
    int highUtil = _counterGaugeNodes.where((n) => n.isGauge && n.utilization > 0.9).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL NODES', '$total', Icons.analytics, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'COUNTERS', '$counters', Icons.add_circle_outline, Colors.teal),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'GAUGES', '$gauges', Icons.speed, Colors.amber),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'ZERO-BASED', '$zeroBased', Icons.exposure_zero, Colors.purple),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'HIGH UTIL (>90%)', '$highUtil', Icons.warning_amber, Colors.red),
      ],
    );
  }

  Widget _buildCounterGaugeFormCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    return Card(
      color: cardBg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _counterGaugeFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Numeric Value',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Select Node Dropdown
                DropdownButtonFormField<YangCounterGauge>(
                  isExpanded: true,
                  initialValue: _selectedCounterGaugeNode,
                  decoration: const InputDecoration(
                    labelText: 'Target Node',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: cardBg,
                  items: _counterGaugeNodes.map((node) {
                    return DropdownMenuItem<YangCounterGauge>(
                      value: node,
                      child: Text(
                        '${node.name} (${node.type.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                onChanged: (YangCounterGauge? val) {
                  if (val != null) {
                    setState(() {
                      _selectedCounterGaugeNode = val;
                      _counterGaugeValueController.text = val.value.toString();
                      _discontinuityChecked = false;
                      _counterGaugeValueError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description and Type Info
              if (_selectedCounterGaugeNode != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCounterGaugeNode!.description,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${_selectedCounterGaugeNode!.type.name} (Max Limit: ${_selectedCounterGaugeNode!.maxLimit != null ? _selectedCounterGaugeNode!.maxLimit.toString() : 'None'})',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // New Value input field
              TextFormField(
                controller: _counterGaugeValueController,
                decoration: InputDecoration(
                  labelText: 'New Numeric Value',
                  helperText: 'Enter non-negative integer (supports 64-bit bounds)',
                  border: const OutlineInputBorder(),
                  errorText: _counterGaugeValueError,
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  if (_counterGaugeValueError != null) {
                    setState(() {
                      _counterGaugeValueError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Discontinuity switch (only for counters)
              if (_selectedCounterGaugeNode != null && _selectedCounterGaugeNode!.isCounter) ...[
                Row(
                  children: [
                    Checkbox(
                      value: _discontinuityChecked,
                      onChanged: (val) {
                        setState(() {
                          _discontinuityChecked = val ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Discontinuity / Re-initialization (Allows decreasing value)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Submit Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: _submitCounterGaugeUpdate,
                      child: const Text('Update Value'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reset to zero button (simulates re-initialization)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () {
                      if (_selectedCounterGaugeNode != null) {
                        try {
                          _counterGaugeService.resetNode(_selectedCounterGaugeNode!.id);
                          _refreshCounterGaugeList();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reset ${_selectedCounterGaugeNode!.name} to zero (discontinuity signaled).'),
                              backgroundColor: theme.primaryColor,
                            ),
                          );
                        } catch (e) {
                          setState(() {
                            _counterGaugeValueError = e.toString().replaceFirst('FormatException: ', '');
                          });
                        }
                      }
                    },
                    child: const Text('Reset to 0'),
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

  Widget _buildCounterGaugeListPane(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final Widget listContent = _counterGaugeNodes.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No nodes registered.'),
            ),
          )
        : ListView.separated(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: _counterGaugeNodes.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final node = _counterGaugeNodes[index];
              final isHighUtil = node.isGauge && node.utilization > 0.9;
              final isMediumUtil = node.isGauge && node.utilization > 0.7 && node.utilization <= 0.9;
              
              Color gaugeColor = Colors.green;
              if (isHighUtil) {
                gaugeColor = Colors.red;
              } else if (isMediumUtil) {
                gaugeColor = Colors.orange;
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Status light / Icon
                  Icon(
                    node.isCounter ? Icons.add_circle_outline : Icons.speed,
                    color: node.isCounter ? Colors.teal : gaugeColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  
                  // Node Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                node.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (node.isCounter ? Colors.teal : Colors.amber).withValues(alpha: 0.1),
                                border: Border.all(
                                  color: (node.isCounter ? Colors.teal : Colors.amber).withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                node.type.name,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: node.isCounter ? Colors.teal : Colors.amber[800] ?? Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (node.isZeroBased) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: Colors.purple.withValues(alpha: 0.4),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Zero-Based',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          node.description,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        if (node.isGauge) ...[
                          // Linear progress utilization bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: node.utilization,
                                    backgroundColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.black12,
                                    valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(node.utilization * 100).toInt()}%',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gaugeColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${node.value} / ${node.maxLimit ?? 'None'}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ] else if (node.isCounter) ...[
                          // For counters: sparkline & latest value
                          Row(
                            children: [
                              const Icon(Icons.trending_up, color: Colors.teal, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Value: ${node.value}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (node.history.length > 1) ...[
                                const Text('Trend: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(width: 4),
                                SparklineWidget(history: node.history, color: Colors.teal),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action buttons: quick select or quick reset
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'Select for Update',
                        onPressed: () {
                          setState(() {
                            _selectedCounterGaugeNode = node;
                            _counterGaugeValueController.text = node.value.toString();
                            _discontinuityChecked = false;
                            _counterGaugeValueError = null;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Reset to 0',
                        onPressed: () {
                          try {
                            _counterGaugeService.resetNode(node.id);
                            _refreshCounterGaugeList();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reset ${node.name} to zero (discontinuity signaled).'),
                                backgroundColor: theme.primaryColor,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to reset: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YANG Node Registries',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            isDesktop ? Expanded(child: listContent) : listContent,
          ],
        ),
      ),
    );
  }
  Widget _buildIdentifiersReferencesHeader(ThemeData theme) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Identifiers & References Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'RFC 9911 / RFC 7950',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentifiersReferencesSummary(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = _identifierNodes.length;
    int oids = _identifierNodes.where((n) => n.type == YangIdentifierType.objectIdentifier).length;
    int oids128 = _identifierNodes.where((n) => n.type == YangIdentifierType.objectIdentifier128).length;
    int yangIds = _identifierNodes.where((n) => n.type == YangIdentifierType.yangIdentifier).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL NODES', '$total', Icons.fingerprint, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'OBJECT IDENTIFIERS', '$oids', Icons.category, Colors.teal),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'OIDs (128 LIMIT)', '$oids128', Icons.data_usage, Colors.amber),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'YANG IDENTIFIERS', '$yangIds', Icons.code, Colors.purple),
      ],
    );
  }

  Widget _buildIdentifierFormCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    return Card(
      color: cardBg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _identifiersFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Identifier String',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Select Node Dropdown
                DropdownButtonFormField<YangIdentifierReference>(
                  isExpanded: true,
                  initialValue: _selectedIdentifierNode,
                  decoration: const InputDecoration(
                    labelText: 'Target Node',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: cardBg,
                  items: _identifierNodes.map((node) {
                    return DropdownMenuItem<YangIdentifierReference>(
                      value: node,
                      child: Text(
                        '${node.name} (${node.type.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (YangIdentifierReference? val) {
                    if (val != null) {
                      setState(() {
                        _selectedIdentifierNode = val;
                        _identifierValueController.text = val.value;
                        _identifierValueError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Description and Type Info
                if (_selectedIdentifierNode != null) ...[
                  Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           _selectedIdentifierNode!.description,
                           style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Type: ${_selectedIdentifierNode!.type.name}',
                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                         ),
                       ],
                     ),
                  ),
                  const SizedBox(height: 16),
                ],

                // New Value input field
                TextFormField(
                  controller: _identifierValueController,
                  decoration: InputDecoration(
                    labelText: 'New Identifier Value',
                    helperText: _selectedIdentifierNode?.type == YangIdentifierType.yangIdentifier
                        ? 'Valid YANG 1.1 identifier format (starts with letter/underscore)'
                        : 'Valid OID dotted-decimal sequence (e.g. 1.3.6.1.4.1)',
                    border: const OutlineInputBorder(),
                    errorText: _identifierValueError,
                  ),
                  onChanged: (val) {
                    if (_identifierValueError != null) {
                      setState(() {
                        _identifierValueError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Submit Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: _submitIdentifierUpdate,
                        child: const Text('Update Identifier'),
                      ),
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

  Widget _buildIdentifierListPane(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final Widget listContent = _identifierNodes.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No nodes registered.'),
            ),
          )
        : ListView.separated(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: _identifierNodes.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final node = _identifierNodes[index];
              IconData icon;
              Color color;
              
              switch (node.type) {
                case YangIdentifierType.objectIdentifier:
                  icon = Icons.category;
                  color = Colors.teal;
                  break;
                case YangIdentifierType.objectIdentifier128:
                  icon = Icons.data_usage;
                  color = Colors.amber[800] ?? Colors.amber;
                  break;
                case YangIdentifierType.yangIdentifier:
                  icon = Icons.code;
                  color = Colors.purple;
                  break;
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                node.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                node.type.name,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          node.description,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.grey, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Value: ${node.value}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Select for Update',
                    onPressed: () {
                      setState(() {
                        _selectedIdentifierNode = node;
                        _identifierValueController.text = node.value;
                        _identifierValueError = null;
                      });
                    },
                  ),
                ],
              );
            },
          );

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YANG Identifiers & OID Registries',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            isDesktop ? Expanded(child: listContent) : listContent,
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeHeader(ThemeData theme) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Date & Time Types Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'RFC 9911 Date-Time Specs',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSummary(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = _dateTimeNodes.length;
    int datetimes = _dateTimeNodes.where((n) => n.type == YangDateTimeType.dateAndTime).length;
    int dates = _dateTimeNodes.where((n) => n.type == YangDateTimeType.date || n.type == YangDateTimeType.dateNoZone).length;
    int times = _dateTimeNodes.where((n) => n.type == YangDateTimeType.time || n.type == YangDateTimeType.timeNoZone).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL NODES', '$total', Icons.calendar_today, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'DATE AND TIMES', '$datetimes', Icons.schedule, Colors.teal),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'DATES', '$dates', Icons.date_range, Colors.amber),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TIMES', '$times', Icons.hourglass_empty, Colors.purple),
      ],
    );
  }

  Widget _buildDateTimeFormCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    return Card(
      color: cardBg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _dateTimeFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Date / Time String',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Select Node Dropdown
                DropdownButtonFormField<YangDateTimeReference>(
                  isExpanded: true,
                  initialValue: _selectedDateTimeNode,
                  decoration: const InputDecoration(
                    labelText: 'Target Node',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: cardBg,
                  items: _dateTimeNodes.map((node) {
                    return DropdownMenuItem<YangDateTimeReference>(
                      value: node,
                      child: Text(
                        '${node.name} (${node.type.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (YangDateTimeReference? val) {
                    if (val != null) {
                      setState(() {
                        _selectedDateTimeNode = val;
                        _dateTimeValueController.text = val.value;
                        _dateTimeValueError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Description and Type Info
                if (_selectedDateTimeNode != null) ...[
                  Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           _selectedDateTimeNode!.description,
                           style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Type: ${_selectedDateTimeNode!.type.name}',
                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                         ),
                       ],
                     ),
                  ),
                  const SizedBox(height: 16),
                ],

                // New Value input field
                TextFormField(
                  controller: _dateTimeValueController,
                  decoration: InputDecoration(
                    labelText: 'New Date/Time Value',
                    helperText: _selectedDateTimeNode == null
                        ? 'Select a node'
                        : 'Format: ${_selectedDateTimeNode!.type == YangDateTimeType.dateAndTime ? 'YYYY-MM-DDTHH:MM:SS(Z|offset)' : (_selectedDateTimeNode!.type == YangDateTimeType.date ? 'YYYY-MM-DD(Z|offset)' : (_selectedDateTimeNode!.type == YangDateTimeType.dateNoZone ? 'YYYY-MM-DD' : (_selectedDateTimeNode!.type == YangDateTimeType.time ? 'HH:MM:SS(Z|offset)' : 'HH:MM:SS')))}',
                    border: const OutlineInputBorder(),
                    errorText: _dateTimeValueError,
                  ),
                  onChanged: (val) {
                    if (_dateTimeValueError != null) {
                      setState(() {
                        _dateTimeValueError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: _submitDateTimeUpdate,
                        child: const Text('Update Value'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: _setToCurrentTime,
                      child: const Text('Set to Current'),
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

  Widget _buildDateTimeListPane(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final Widget listContent = _dateTimeNodes.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No nodes registered.'),
            ),
          )
        : ListView.separated(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: _dateTimeNodes.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final node = _dateTimeNodes[index];
              IconData icon;
              Color color;
              
              switch (node.type) {
                case YangDateTimeType.dateAndTime:
                  icon = Icons.schedule;
                  color = Colors.teal;
                  break;
                case YangDateTimeType.date:
                  icon = Icons.date_range;
                  color = Colors.amber[800] ?? Colors.amber;
                  break;
                case YangDateTimeType.dateNoZone:
                  icon = Icons.calendar_today;
                  color = Colors.blue;
                  break;
                case YangDateTimeType.time:
                  icon = Icons.hourglass_empty;
                  color = Colors.purple;
                  break;
                case YangDateTimeType.timeNoZone:
                  icon = Icons.access_time;
                  color = Colors.deepOrange;
                  break;
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                node.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                node.type.name,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          node.description,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.grey, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Value: ${node.value}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Select for Update',
                    onPressed: () {
                      setState(() {
                        _selectedDateTimeNode = node;
                        _dateTimeValueController.text = node.value;
                        _dateTimeValueError = null;
                      });
                    },
                  ),
                ],
              );
            },
          );

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YANG Date & Time Registry',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            isDesktop ? Expanded(child: listContent) : listContent,
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDurationHeader(ThemeData theme) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Time Durations Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'RFC 9911 Time-Duration Specs',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDurationSummary(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = _timeDurationNodes.length;
    int ticks = _timeDurationNodes.where((n) => n.type == YangTimeDurationType.timeticks || n.type == YangTimeDurationType.timestamp).length;
    int stdDurations = _timeDurationNodes.where((n) => n.type != YangTimeDurationType.timeticks && n.type != YangTimeDurationType.timestamp).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL NODES', '$total', Icons.timer, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TIMETICKS & STAMPS', '$ticks', Icons.av_timer, Colors.teal),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'DURATIONS', '$stdDurations', Icons.hourglass_bottom, Colors.purple),
      ],
    );
  }

  Widget _buildTimeDurationFormCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    return Card(
      color: cardBg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _timeDurationFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Time Duration / Ticks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Select Node Dropdown
                DropdownButtonFormField<YangTimeDurationReference>(
                  isExpanded: true,
                  initialValue: _selectedTimeDurationNode,
                  decoration: const InputDecoration(
                    labelText: 'Target Node',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: cardBg,
                  items: _timeDurationNodes.map((node) {
                    return DropdownMenuItem<YangTimeDurationReference>(
                      value: node,
                      child: Text(
                        '${node.name} (${node.type.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (YangTimeDurationReference? val) {
                    if (val != null) {
                      setState(() {
                        _selectedTimeDurationNode = val;
                        _timeDurationValueController.text = val.value;
                        _timeDurationValueError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Description and Type Info
                if (_selectedTimeDurationNode != null) ...[
                  Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           _selectedTimeDurationNode!.description,
                           style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Type: ${_selectedTimeDurationNode!.type.name}',
                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                         ),
                         if (_selectedTimeDurationNode!.associatedNodeId != null) ...[
                           const SizedBox(height: 4),
                           Text(
                             'Associated Ticks: ${_selectedTimeDurationNode!.associatedNodeId}',
                             style: const TextStyle(fontSize: 11, color: Colors.grey),
                           ),
                         ],
                       ],
                     ),
                  ),
                  const SizedBox(height: 16),
                ],

                // New Value input field
                TextFormField(
                  controller: _timeDurationValueController,
                  decoration: InputDecoration(
                    labelText: 'New Value',
                    helperText: _selectedTimeDurationNode == null
                        ? 'Select a node'
                        : 'Type: ${_selectedTimeDurationNode!.type.name}',
                    border: const OutlineInputBorder(),
                    errorText: _timeDurationValueError,
                  ),
                  onChanged: (val) {
                    if (_timeDurationValueError != null) {
                      setState(() {
                        _timeDurationValueError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: _submitTimeDurationUpdate,
                        child: const Text('Update Value'),
                      ),
                    ),
                    if (_selectedTimeDurationNode?.type == YangTimeDurationType.timeticks) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: _simulateWrapAround,
                        child: const Text('Simulate Wrap'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDurationListPane(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final Widget listContent = _timeDurationNodes.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No nodes registered.'),
            ),
          )
        : ListView.separated(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: _timeDurationNodes.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final node = _timeDurationNodes[index];
              IconData icon;
              Color color;
              
              switch (node.type) {
                case YangTimeDurationType.timeticks:
                  icon = Icons.av_timer;
                  color = Colors.teal;
                  break;
                case YangTimeDurationType.timestamp:
                  icon = Icons.restore;
                  color = Colors.blue;
                  break;
                case YangTimeDurationType.nanoseconds32:
                case YangTimeDurationType.nanoseconds64:
                  icon = Icons.flash_on;
                  color = Colors.amber[800] ?? Colors.amber;
                  break;
                case YangTimeDurationType.microseconds32:
                case YangTimeDurationType.microseconds64:
                  icon = Icons.shutter_speed;
                  color = Colors.purple;
                  break;
                default:
                  icon = Icons.hourglass_bottom;
                  color = Colors.deepOrange;
                  break;
              }

              // Build helper string to convert to human readable format
              String humanReadable = '';
              final val = BigInt.tryParse(node.value);
              if (val != null) {
                if (node.type == YangTimeDurationType.seconds32) {
                  if (val >= BigInt.from(60)) {
                    final mins = val.toDouble() / 60.0;
                    humanReadable = ' (${mins.toStringAsFixed(1)} min)';
                  }
                } else if (node.type == YangTimeDurationType.nanoseconds32) {
                  final secVal = val.toDouble() / 1e9;
                  humanReadable = ' (${secVal.toStringAsFixed(3)} sec)';
                } else if (node.type == YangTimeDurationType.timeticks || node.type == YangTimeDurationType.timestamp) {
                  final secVal = val.toDouble() / 100.0;
                  humanReadable = ' (${secVal.toStringAsFixed(2)} sec)';
                }
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                node.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                node.type.name,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          node.description,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.grey, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Value: ${node.value}$humanReadable',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Select for Update',
                    onPressed: () {
                      setState(() {
                        _selectedTimeDurationNode = node;
                        _timeDurationValueController.text = node.value;
                        _timeDurationValueError = null;
                      });
                    },
                  ),
                ],
              );
            },
          );

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YANG Time Durations Registry',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            isDesktop ? Expanded(child: listContent) : listContent,
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTagHeader(ThemeData theme) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Addresses & Tags Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'RFC 9911 Address Specs',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressTagSummary(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = _addressTagNodes.length;
    int addresses = _addressTagNodes.where((n) => n.type == YangAddressTagType.physAddress || n.type == YangAddressTagType.macAddress || n.type == YangAddressTagType.dottedQuad).length;
    int tags = _addressTagNodes.where((n) => n.type == YangAddressTagType.languageTag || n.type == YangAddressTagType.xpath10 || n.type == YangAddressTagType.uuid).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL NODES', '$total', Icons.tag, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'ADDRESS TYPES', '$addresses', Icons.settings_ethernet, Colors.teal),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'IDENTITIES & TAGS', '$tags', Icons.fingerprint, Colors.purple),
      ],
    );
  }

  Widget _buildAddressTagFormCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    return Card(
      color: cardBg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _addressTagFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Address / Identity Tag',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<YangAddressTagReference>(
                  isExpanded: true,
                  initialValue: _selectedAddressTagNode,
                  decoration: const InputDecoration(
                    labelText: 'Target Node',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: cardBg,
                  items: _addressTagNodes.map((node) {
                    return DropdownMenuItem<YangAddressTagReference>(
                      value: node,
                      child: Text(
                        '${node.name} (${node.type.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (YangAddressTagReference? val) {
                    if (val != null) {
                      setState(() {
                        _selectedAddressTagNode = val;
                        _addressTagValueController.text = val.value;
                        _addressTagValueError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                if (_selectedAddressTagNode != null) ...[
                  Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           _selectedAddressTagNode!.description,
                           style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Type: ${_selectedAddressTagNode!.type.name}',
                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                         ),
                       ],
                     ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _addressTagValueController,
                  decoration: InputDecoration(
                    labelText: 'New Value',
                    helperText: _selectedAddressTagNode == null
                        ? 'Select a node'
                        : 'Type: ${_selectedAddressTagNode!.type.name}',
                    border: const OutlineInputBorder(),
                    errorText: _addressTagValueError,
                  ),
                  onChanged: (val) {
                    if (_addressTagValueError != null) {
                      setState(() {
                        _addressTagValueError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: _submitAddressTagUpdate,
                        child: const Text('Update Value'),
                      ),
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

  Widget _buildAddressTagListPane(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final Widget listContent = _addressTagNodes.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No nodes registered.'),
            ),
          )
        : ListView.separated(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: _addressTagNodes.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final node = _addressTagNodes[index];
              IconData icon;
              Color color;
              
              switch (node.type) {
                case YangAddressTagType.physAddress:
                  icon = Icons.settings_ethernet;
                  color = Colors.teal;
                  break;
                case YangAddressTagType.macAddress:
                  icon = Icons.settings_input_hdmi;
                  color = Colors.blue;
                  break;
                case YangAddressTagType.uuid:
                  icon = Icons.fingerprint;
                  color = Colors.purple;
                  break;
                case YangAddressTagType.dottedQuad:
                  icon = Icons.lan;
                  color = Colors.indigo;
                  break;
                case YangAddressTagType.languageTag:
                  icon = Icons.translate;
                  color = Colors.green;
                  break;
                case YangAddressTagType.xpath10:
                  icon = Icons.code;
                  color = Colors.amber[800] ?? Colors.amber;
                  break;
                default:
                  icon = Icons.tag;
                  color = Colors.deepOrange;
                  break;
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                node.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                node.type.name,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          node.description,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.grey, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Value: ${node.value}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Select for Update',
                    onPressed: () {
                      setState(() {
                        _selectedAddressTagNode = node;
                        _addressTagValueController.text = node.value;
                        _addressTagValueError = null;
                      });
                    },
                  ),
                ],
              );
            },
          );

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YANG Addresses & Tags Registry',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            isDesktop ? Expanded(child: listContent) : listContent,
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentRacksHeader(ThemeData theme) {
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

  Widget _buildEquipmentRacksSummary(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    final total = _equipmentRacks.length;
    final standard = _equipmentRacks.where((r) => r.rackClass == 'rack-standard').length;
    final secure = total - standard;
    
    double avgHeight = 0;
    double avgWidth = 0;
    double avgDepth = 0;
    if (total > 0) {
      avgHeight = _equipmentRacks.map((r) => r.height).reduce((a, b) => a + b) / total;
      avgWidth = _equipmentRacks.map((r) => r.width).reduce((a, b) => a + b) / total;
      avgDepth = _equipmentRacks.map((r) => r.depth).reduce((a, b) => a + b) / total;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL RACKS', '$total', Icons.grid_view, Colors.blue),
          _buildMiniStatusCard(theme, cardBg, borderSide, 'STANDARD GENERAL', '$standard', Icons.check_circle_outline, Colors.cyan),
          _buildMiniStatusCard(theme, cardBg, borderSide, 'SECURED CABINETS', '$secure', Icons.security, Colors.redAccent),
          _buildMiniStatusCard(theme, cardBg, borderSide, 'AVG HEIGHT (mm)', avgHeight.toStringAsFixed(0), Icons.height, Colors.amber),
          _buildMiniStatusCard(theme, cardBg, borderSide, 'AVG WIDTH/DEPTH', '${avgWidth.toStringAsFixed(0)} / ${avgDepth.toStringAsFixed(0)}', Icons.settings_overscan, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildEquipmentRackFormCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _equipmentRackFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditingRack ? 'EDIT RACK PROPERTIES' : 'PROVISION NEW EQUIPMENT RACK',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // ID Field (Disabled if editing)
              TextFormField(
                controller: _rackIdController,
                enabled: !_isEditingRack,
                decoration: InputDecoration(
                  labelText: 'Rack ID',
                  border: const OutlineInputBorder(),
                  errorText: _rackIdError,
                ),
              ),
              const SizedBox(height: 16),

              // Classification Identity Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedRackClass,
                decoration: const InputDecoration(
                  labelText: 'Rack Classification (identityref)',
                  border: OutlineInputBorder(),
                ),
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

              // Physical dimensions
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rackHeightController,
                      decoration: InputDecoration(
                        labelText: 'Height (mm)',
                        border: const OutlineInputBorder(),
                        errorText: _rackHeightError,
                        helperText: 'Standard: 1866mm (42U)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rackWidthController,
                      decoration: InputDecoration(
                        labelText: 'Width (mm)',
                        border: const OutlineInputBorder(),
                        errorText: _rackWidthError,
                        helperText: 'Standard: 600mm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rackDepthController,
                      decoration: InputDecoration(
                        labelText: 'Depth (mm)',
                        border: const OutlineInputBorder(),
                        errorText: _rackDepthError,
                        helperText: 'Standard: 1000mm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location Placement Section
              const Text(
                'PHYSICAL LOCATION & GRID PLACEMENT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // Location Dropdown
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _rackFormLocationId,
                decoration: const InputDecoration(
                  labelText: 'Physical Location Reference',
                  border: OutlineInputBorder(),
                  helperText: 'Select facility to place the rack on the floor plan',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Unassigned (None)'),
                  ),
                  ..._inventoryLocations.map((loc) => DropdownMenuItem<String>(
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

              // Grid Coordinates (Row & Column)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rackRowController,
                      decoration: InputDecoration(
                        labelText: 'Grid Row',
                        border: const OutlineInputBorder(),
                        errorText: _rackRowError,
                        helperText: 'Positive integer (>= 1)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rackColController,
                      decoration: InputDecoration(
                        labelText: 'Grid Column',
                        border: const OutlineInputBorder(),
                        errorText: _rackColError,
                        helperText: 'Positive integer (>= 1)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Timestamp field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rackTimestampController,
                      decoration: InputDecoration(
                        labelText: 'Recording Timestamp (ISO 8601)',
                        border: const OutlineInputBorder(),
                        errorText: _rackTimestampError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _rackTimestampController.text = DateTime.now().toUtc().toIso8601String();
                        });
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

              // Valid Until field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rackValidUntilController,
                      decoration: InputDecoration(
                        labelText: 'Expiration Timestamp (ISO 8601)',
                        border: const OutlineInputBorder(),
                        errorText: _rackValidUntilError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _rackValidUntilController.text = DateTime.now().toUtc().add(const Duration(days: 365)).toIso8601String();
                        });
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

              // Error messages from backend / validator
              if (_rackFormError != null) ...[
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
                          _rackFormError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isEditingRack) ...[
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditingRack = false;
                          _rackIdController.clear();
                          _rackHeightController.clear();
                          _rackWidthController.clear();
                          _rackDepthController.clear();
                          _rackTimestampController.clear();
                          _rackValidUntilController.clear();
                          _rackRowController.clear();
                          _rackColController.clear();
                          _rackFormLocationId = null;
                          _selectedRackClass = 'rack-standard';
                          _rackFormError = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: _submitEquipmentRackSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(_isEditingRack ? 'UPDATE PROPERTIES' : 'PROVISION RACK'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _equipmentRackService.reset();
                    _refreshEquipmentRackList();
                  });
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

  Widget _buildEquipmentRackListPane(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final listContent = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _equipmentRacks.length,
      itemBuilder: (context, index) {
        final rack = _equipmentRacks[index];
        final isSelected = _selectedEquipmentRack?.id == rack.id;
        
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
                    setState(() {
                      _isEditingRack = true;
                      _selectedEquipmentRack = rack;
                      _rackIdController.text = rack.id;
                      _selectedRackClass = rack.rackClass;
                      _rackHeightController.text = rack.height.toString();
                      _rackWidthController.text = rack.width.toString();
                      _rackDepthController.text = rack.depth.toString();
                      _rackTimestampController.text = rack.timestamp.toIso8601String();
                      _rackValidUntilController.text = rack.validUntil.toIso8601String();
                      if (rack.rackLocation != null) {
                        _rackFormLocationId = rack.rackLocation!.locationRef;
                        _rackRowController.text = rack.rackLocation!.rowNumber?.toString() ?? '';
                        _rackColController.text = rack.rackLocation!.columnNumber?.toString() ?? '';
                      } else {
                        _rackFormLocationId = null;
                        _rackRowController.clear();
                        _rackColController.clear();
                      }
                      _rackFormError = null;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _equipmentRackService.deleteRack(rack.id);
                      _refreshEquipmentRackList();
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedEquipmentRack = rack;
              });
            },
          ),
        ),
      );
    },
    );

    final visualizerContent = _selectedEquipmentRack != null
        ? USlotGridVisualizer(
            rack: _selectedEquipmentRack!,
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

  Widget _buildFacilityFloorPlanCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    final activeLocationId = _selectedPlacementLocationId ?? '';
    final placedRacks = _equipmentRacks.where((rack) =>
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
                    key: const Key('facility-selector-dropdown'),
                    isExpanded: true,
                    initialValue: _selectedPlacementLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Select Facility Location',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _inventoryLocations.map((loc) => DropdownMenuItem<String>(
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

                      final isSelectedCell = _rackRowController.text == row.toString() &&
                                             _rackColController.text == col.toString() &&
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
                            _rackRowController.text = row.toString();
                            _rackColController.text = col.toString();
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

  void _refreshEquipmentRackList() {
    setState(() {
      _equipmentRacks = _equipmentRackService.getRacks();
      if (_selectedEquipmentRack != null) {
        final existingIndex = _equipmentRacks.indexWhere((r) => r.id == _selectedEquipmentRack!.id);
        if (existingIndex != -1) {
          _selectedEquipmentRack = _equipmentRacks[existingIndex];
        } else {
          _selectedEquipmentRack = null;
        }
      }
      if (_selectedEquipmentRack == null && _equipmentRacks.isNotEmpty) {
        _selectedEquipmentRack = _equipmentRacks.first;
      }
    });
  }

  void _submitEquipmentRackSave() {
    setState(() {
      _rackFormError = null;
      _rackIdError = null;
      _rackHeightError = null;
      _rackWidthError = null;
      _rackDepthError = null;
      _rackTimestampError = null;
      _rackValidUntilError = null;
      _rackRowError = null;
      _rackColError = null;
    });

    final id = _rackIdController.text.trim();
    final rackClass = _selectedRackClass ?? 'rack-standard';
    final heightText = _rackHeightController.text.trim();
    final widthText = _rackWidthController.text.trim();
    final depthText = _rackDepthController.text.trim();
    final timestampText = _rackTimestampController.text.trim();
    final validUntilText = _rackValidUntilController.text.trim();
    final locationRef = _rackFormLocationId;
    final rowText = _rackRowController.text.trim();
    final colText = _rackColController.text.trim();

    bool hasError = false;

    if (!_isEditingRack && id.isEmpty) {
      setState(() => _rackIdError = 'ID cannot be empty');
      hasError = true;
    }

    int height = 0;
    if (heightText.isEmpty) {
      setState(() => _rackHeightError = 'Height is required');
      hasError = true;
    } else {
      final parsed = int.tryParse(heightText);
      if (parsed == null || parsed <= 0 || parsed > 65535) {
        setState(() => _rackHeightError = 'Must be a positive integer between 1 and 65535');
        hasError = true;
      } else {
        height = parsed;
      }
    }

    int width = 0;
    if (widthText.isEmpty) {
      setState(() => _rackWidthError = 'Width is required');
      hasError = true;
    } else {
      final parsed = int.tryParse(widthText);
      if (parsed == null || parsed <= 0 || parsed > 65535) {
        setState(() => _rackWidthError = 'Must be a positive integer between 1 and 65535');
        hasError = true;
      } else {
        width = parsed;
      }
    }

    int depth = 0;
    if (depthText.isEmpty) {
      setState(() => _rackDepthError = 'Depth is required');
      hasError = true;
    } else {
      final parsed = int.tryParse(depthText);
      if (parsed == null || parsed <= 0 || parsed > 65535) {
        setState(() => _rackDepthError = 'Must be a positive integer between 1 and 65535');
        hasError = true;
      } else {
        depth = parsed;
      }
    }

    DateTime? timestamp;
    if (timestampText.isEmpty) {
      setState(() => _rackTimestampError = 'Timestamp is required');
      hasError = true;
    } else {
      try {
        timestamp = DateTime.parse(timestampText);
      } catch (e) {
        setState(() => _rackTimestampError = 'Invalid format. Use YYYY-MM-DD HH:MM:SS');
        hasError = true;
      }
    }

    DateTime? validUntil;
    if (validUntilText.isEmpty) {
      setState(() => _rackValidUntilError = 'Valid Until is required');
      hasError = true;
    } else {
      try {
        validUntil = DateTime.parse(validUntilText);
      } catch (e) {
        setState(() => _rackValidUntilError = 'Invalid format. Use YYYY-MM-DD HH:MM:SS');
        hasError = true;
      }
    }

    if (!hasError && timestamp != null && validUntil != null) {
      if (!validUntil.isAfter(timestamp)) {
        setState(() => _rackValidUntilError = 'Valid-until must be after timestamp');
        hasError = true;
      }
    }

    int? rowNumber;
    if (rowText.isNotEmpty) {
      final parsed = int.tryParse(rowText);
      if (parsed == null || parsed <= 0 || parsed > 4294967295) {
        setState(() => _rackRowError = 'Must be a positive uint32 integer (>= 1)');
        hasError = true;
      } else {
        rowNumber = parsed;
      }
    }

    int? columnNumber;
    if (colText.isNotEmpty) {
      final parsed = int.tryParse(colText);
      if (parsed == null || parsed <= 0 || parsed > 4294967295) {
        setState(() => _rackColError = 'Must be a positive uint32 integer (>= 1)');
        hasError = true;
      } else {
        columnNumber = parsed;
      }
    }

    if (hasError) return;

    RackLocation? rackLocation;
    if (locationRef != null && locationRef.isNotEmpty) {
      rackLocation = RackLocation(
        locationRef: locationRef,
        rowNumber: rowNumber,
        columnNumber: columnNumber,
      );
    }

    final validLocationIds = _inventoryLocations.map((loc) => loc.id).toSet();

    try {
      if (_isEditingRack && _selectedEquipmentRack != null) {
        final updatedRack = EquipmentRack(
          id: _selectedEquipmentRack!.id,
          rackClass: rackClass,
          height: height,
          width: width,
          depth: depth,
          timestamp: timestamp!,
          validUntil: validUntil!,
          rackLocation: rackLocation,
        );
        _equipmentRackService.updateRack(
          _selectedEquipmentRack!.id,
          updatedRack,
          validLocationIds: validLocationIds,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated rack ${_selectedEquipmentRack!.id}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final newRack = EquipmentRack(
          id: id,
          rackClass: rackClass,
          height: height,
          width: width,
          depth: depth,
          timestamp: timestamp!,
          validUntil: validUntil!,
          rackLocation: rackLocation,
        );
        _equipmentRackService.addRack(newRack, validLocationIds: validLocationIds);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added rack $id'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reset form and refresh list
      _rackIdController.clear();
      _rackHeightController.clear();
      _rackWidthController.clear();
      _rackDepthController.clear();
      _rackTimestampController.clear();
      _rackValidUntilController.clear();
      _rackRowController.clear();
      _rackColController.clear();
      setState(() {
        _selectedRackClass = 'rack-standard';
        _rackFormLocationId = null;
        _isEditingRack = false;
      });
      _refreshEquipmentRackList();
    } catch (e) {
      setState(() {
        _rackFormError = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  void _refreshInventoryLocationList() {
    setState(() {
      _inventoryLocations = _inventoryLocationService.getLocations();
      if (_selectedInventoryLocation != null) {
        final existingIndex = _inventoryLocations.indexWhere((l) => l.id == _selectedInventoryLocation!.id);
        if (existingIndex != -1) {
          _selectedInventoryLocation = _inventoryLocations[existingIndex];
        } else {
          _selectedInventoryLocation = null;
        }
      }
      if ((_selectedPlacementLocationId == null || _selectedPlacementLocationId!.isEmpty) && _inventoryLocations.isNotEmpty) {
        _selectedPlacementLocationId = _inventoryLocations.first.id;
      }
    });
  }

  void _submitInventoryLocationSave() {
    setState(() {
      _locationFormError = null;
      _locationIdError = null;
      _locationTypeError = null;
      _locationTimestampError = null;
      _locationValidUntilError = null;
      _locationCountryCodeError = null;
    });

    final id = _locationIdController.text.trim();
    final type = _locationTypeController.text.trim();
    final parent = _selectedLocationParentId;
    final timestampText = _locationTimestampController.text.trim();
    final validUntilText = _locationValidUntilController.text.trim();
    final address = _locationAddressController.text.trim();
    final postalCode = _locationPostalCodeController.text.trim();
    final stateStr = _locationStateController.text.trim();
    final city = _locationCityController.text.trim();
    final countryCode = _locationCountryCodeController.text.trim();

    bool hasError = false;

    if (!_isEditingLocation && id.isEmpty) {
      setState(() => _locationIdError = 'ID cannot be empty');
      hasError = true;
    }
    if (type.isEmpty) {
      setState(() => _locationTypeError = 'Type cannot be empty');
      hasError = true;
    }

    DateTime? timestamp;
    if (timestampText.isEmpty) {
      setState(() => _locationTimestampError = 'Timestamp is required');
      hasError = true;
    } else {
      try {
        timestamp = DateTime.parse(timestampText);
      } catch (e) {
        setState(() => _locationTimestampError = 'Invalid format. Use YYYY-MM-DD HH:MM:SS');
        hasError = true;
      }
    }

    DateTime? validUntil;
    if (validUntilText.isNotEmpty) {
      try {
        validUntil = DateTime.parse(validUntilText);
      } catch (e) {
        setState(() => _locationValidUntilError = 'Invalid format. Use YYYY-MM-DD HH:MM:SS');
        hasError = true;
      }
    }

    PhysicalAddress? physicalAddress;
    if (address.isNotEmpty || postalCode.isNotEmpty || stateStr.isNotEmpty || city.isNotEmpty || countryCode.isNotEmpty) {
      if (countryCode.isEmpty) {
        setState(() => _locationCountryCodeError = 'Country code is required if address is provided');
        hasError = true;
      } else {
        try {
          InventoryLocationValidator.validateCountryCode(countryCode);
        } catch (e) {
          setState(() => _locationCountryCodeError = e.toString().replaceFirst('FormatException: ', ''));
          hasError = true;
        }
      }
      if (!hasError) {
        physicalAddress = PhysicalAddress(
          address: address,
          postalCode: postalCode,
          state: stateStr,
          city: city,
          countryCode: countryCode,
        );
      }
    }

    if (hasError) return;

    try {
      if (_isEditingLocation && _selectedInventoryLocation != null) {
        _inventoryLocationService.updateLocation(
          _selectedInventoryLocation!.id,
          type: type,
          parent: parent,
          timestamp: timestamp!,
          validUntil: validUntil,
          physicalAddress: physicalAddress,
          containedChassis: _editingContainedChassis,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated location ${_selectedInventoryLocation!.id}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final newLoc = InventoryLocation(
          id: id,
          type: type,
          parent: parent,
          timestamp: timestamp!,
          validUntil: validUntil,
          physicalAddress: physicalAddress,
          containedChassis: _editingContainedChassis,
        );
        _inventoryLocationService.addLocation(newLoc);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added location $id'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reset form and refresh list
      _locationIdController.clear();
      _locationTypeController.clear();
      _locationTimestampController.clear();
      _locationValidUntilController.clear();
      _locationAddressController.clear();
      _locationPostalCodeController.clear();
      _locationStateController.clear();
      _locationCityController.clear();
      _locationCountryCodeController.clear();
      _chassisIdController.clear();
      setState(() {
        _editingContainedChassis = [];
        _chassisNeRef = null;
        _chassisComponentRef = null;
        _chassisError = null;
        _selectedLocationParentId = null;
        _isEditingLocation = false;
        _selectedInventoryLocation = null;
        _locationCountryCodeError = null;
      });
      _refreshInventoryLocationList();
    } catch (e) {
      setState(() {
        _locationFormError = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  List<Map<String, dynamic>> _buildFlattenedTree() {
    final Map<String?, List<InventoryLocation>> parentToChildren = {};
    for (final loc in _inventoryLocations) {
      parentToChildren.putIfAbsent(loc.parent, () => []).add(loc);
    }

    final List<Map<String, dynamic>> result = [];
    final Set<String> visited = {};

    void traverse(String? parentId, int depth) {
      final children = parentToChildren[parentId] ?? [];
      children.sort((a, b) => a.id.compareTo(b.id));
      for (final child in children) {
        if (visited.contains(child.id)) continue;
        visited.add(child.id);
        result.add({
          'location': child,
          'depth': depth,
        });
        traverse(child.id, depth + 1);
      }
    }

    final allIds = _inventoryLocations.map((l) => l.id).toSet();
    final roots = _inventoryLocations.where((l) => l.parent == null || !allIds.contains(l.parent)).toList();
    roots.sort((a, b) => a.id.compareTo(b.id));

    for (final root in roots) {
      if (visited.contains(root.id)) continue;
      visited.add(root.id);
      result.add({
        'location': root,
        'depth': 0,
      });
      traverse(root.id, 1);
    }

    for (final loc in _inventoryLocations) {
      if (!visited.contains(loc.id)) {
        result.add({
          'location': loc,
          'depth': 0,
        });
      }
    }

    return result;
  }

  Widget _buildNetworkInventoryManager(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final neList = _networkInventoryService.getNetworkElements();

    return Card(
      color: cardBg,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.inventory, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Network Inventory Manager (YANG Data Source)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        initiallyExpanded: _isNeManagerExpanded,
        onExpansionChanged: (val) {
          setState(() {
            _isNeManagerExpanded = val;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error display
                if (_neManagerError != null) ...[
                  Text(
                    _neManagerError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
                // Add Network Element Form
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _newNeIdController,
                        decoration: const InputDecoration(
                          labelText: 'New Network Element ID (ne-id)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final neId = _newNeIdController.text.trim();
                        if (neId.isEmpty) {
                          setState(() => _neManagerError = 'NE ID is required.');
                          return;
                        }
                        try {
                          _networkInventoryService.addNetworkElement(
                            MockNetworkElement(neId: neId, componentIds: []),
                          );
                          setState(() {
                            _newNeIdController.clear();
                            _neManagerError = null;
                          });
                        } catch (e) {
                          setState(() => _neManagerError = e.toString().replaceFirst('FormatException: ', ''));
                        }
                      },
                      child: const Text('Add NE'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Registered Network Elements & Components:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (neList.isEmpty)
                  const Text(
                    'No network elements in inventory.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  )
                else
                  ...neList.map((ne) {
                    final isAddingComp = _selectedNeForNewComponent == ne.neId;

                    return Card(
                      color: isDark ? const Color(0xFF343537) : Colors.grey.shade50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.router, size: 16, color: Colors.blueGrey),
                                    const SizedBox(width: 6),
                                    Text(
                                      ne.neId,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.add, size: 14),
                                      label: const Text('Add Component', style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        setState(() {
                                          if (isAddingComp) {
                                            _selectedNeForNewComponent = null;
                                          } else {
                                            _selectedNeForNewComponent = ne.neId;
                                          }
                                          _newComponentIdController.clear();
                                          _neManagerError = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                      tooltip: 'Delete NE',
                                      onPressed: () {
                                        setState(() {
                                          _networkInventoryService.deleteNetworkElement(ne.neId);
                                          _neManagerError = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (ne.componentIds.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'No components in this network element.',
                                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: ne.componentIds.map((comp) {
                                  return Chip(
                                    label: Text(comp, style: const TextStyle(fontSize: 11)),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onDeleted: () {
                                      setState(() {
                                        _networkInventoryService.deleteComponent(ne.neId, comp);
                                        _neManagerError = null;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            if (isAddingComp) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _newComponentIdController,
                                      decoration: const InputDecoration(
                                        labelText: 'New Component ID (component-id)',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      final compId = _newComponentIdController.text.trim();
                                      if (compId.isEmpty) {
                                        setState(() => _neManagerError = 'Component ID is required.');
                                        return;
                                      }
                                      try {
                                        _networkInventoryService.addComponent(ne.neId, compId);
                                        setState(() {
                                          _newComponentIdController.clear();
                                          _selectedNeForNewComponent = null;
                                          _neManagerError = null;
                                        });
                                      } catch (e) {
                                        setState(() => _neManagerError = e.toString().replaceFirst('FormatException: ', ''));
                                      }
                                    },
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryLocationHeader(ThemeData theme) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Inventory Locations Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'IETF NI-Location Specs',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryLocationSummary(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = _inventoryLocations.length;
    int active = _inventoryLocations.where((l) => !l.isExpired).length;
    int expired = _inventoryLocations.where((l) => l.isExpired).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL LOCATIONS', '$total', Icons.account_tree, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'ACTIVE HIERARCHIES', '$active', Icons.check_circle_outline, Colors.green),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'EXPIRED NODES', '$expired', Icons.error_outline, Colors.red),
      ],
    );
  }

  Widget _buildInventoryLocationFormCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    // Filter potential parent locations to avoid circular loops
    final potentialParents = _inventoryLocations.where((loc) {
      if (!_isEditingLocation || _selectedInventoryLocation == null) return true;
      // Do not allow setting itself or any nested child as parent
      if (loc.id == _selectedInventoryLocation!.id) return false;
      try {
        InventoryLocationValidator.detectCircularLoop(_selectedInventoryLocation!.id, loc.id, _inventoryLocations);
        return true;
      } catch (_) {
        return false;
      }
    }).toList();

    return Card(
      color: cardBg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _inventoryLocationFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditingLocation ? 'Edit Location' : 'Create Location',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_isEditingLocation)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditingLocation = false;
                            _selectedInventoryLocation = null;
                            _locationIdController.clear();
                            _locationTypeController.clear();
                            _locationTimestampController.clear();
                            _locationValidUntilController.clear();
                            _locationAddressController.clear();
                            _locationPostalCodeController.clear();
                            _locationStateController.clear();
                            _locationCityController.clear();
                            _locationCountryCodeController.clear();
                            _chassisIdController.clear();
                            _editingContainedChassis = [];
                            _chassisNeRef = null;
                            _chassisComponentRef = null;
                            _chassisError = null;
                            _selectedLocationParentId = null;
                            _locationFormError = null;
                            _locationCountryCodeError = null;
                          });
                        },
                        child: const Text('Cancel Edit'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_locationFormError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _locationFormError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                TextFormField(
                  controller: _locationIdController,
                  enabled: !_isEditingLocation,
                  decoration: InputDecoration(
                    labelText: 'Location ID (Unique)',
                    border: const OutlineInputBorder(),
                    errorText: _locationIdError,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationTypeController,
                  decoration: InputDecoration(
                    labelText: 'Type (e.g. site, room, floor)',
                    border: const OutlineInputBorder(),
                    errorText: _locationTypeError,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('parentLocationDropdown'),
                  isExpanded: true,
                  initialValue: _selectedLocationParentId,
                  decoration: const InputDecoration(
                    labelText: 'Parent Location (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: cardBg,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None (Root Node)'),
                    ),
                    ...potentialParents.map((loc) {
                      return DropdownMenuItem<String>(
                        value: loc.id,
                        child: Text('${loc.id} (${loc.type})'),
                      );
                    }),
                  ],
                  onChanged: (String? val) {
                    setState(() {
                      _selectedLocationParentId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationTimestampController,
                  decoration: InputDecoration(
                    labelText: 'Record Timestamp',
                    helperText: 'Format: YYYY-MM-DD HH:MM:SS',
                    border: const OutlineInputBorder(),
                    errorText: _locationTimestampError,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationValidUntilController,
                  decoration: InputDecoration(
                    labelText: 'Valid Until (Optional Expiration)',
                    helperText: 'Format: YYYY-MM-DD HH:MM:SS',
                    border: const OutlineInputBorder(),
                    errorText: _locationValidUntilError,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Physical Address (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationCityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _locationStateController,
                        decoration: const InputDecoration(
                          labelText: 'State/Region',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationPostalCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Postal/ZIP Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _locationCountryCodeController,
                        decoration: InputDecoration(
                          labelText: 'Country Code (ISO-2)',
                          helperText: 'e.g. US, GB',
                          border: const OutlineInputBorder(),
                          errorText: _locationCountryCodeError,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'Contained Chassis Configurations',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_editingContainedChassis.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No chassis directly contained in this location.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                    ),
                  )
                else
                  ..._editingContainedChassis.map((chassis) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF3D3E40)
                            : Colors.grey.shade100,
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Chassis #${chassis.chassisId} (NE: ${chassis.neRef}, Component: ${chassis.componentRef})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _editingContainedChassis.remove(chassis);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Contained Chassis Instance',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _chassisIdController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Chassis ID',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('neRefDropdown_${_chassisNeRef ?? "none"}'),
                              initialValue: _chassisNeRef,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Network Element Ref',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _networkInventoryService.getNetworkElements().map((ne) {
                                return DropdownMenuItem<String>(
                                  value: ne.neId,
                                  child: Text(ne.neId),
                                );
                              }).toList(),
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
                              key: ValueKey('compRefDropdown_${_chassisComponentRef ?? "none"}_ne_${_chassisNeRef ?? "none"}'),
                              initialValue: _chassisComponentRef,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Component Ref',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _chassisNeRef == null
                                  ? []
                                  : (_networkInventoryService.getNetworkElement(_chassisNeRef!)?.componentIds ?? []).map((comp) {
                                      return DropdownMenuItem<String>(
                                        value: comp,
                                        child: Text(comp),
                                      );
                                    }).toList(),
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
                          style: const TextStyle(color: Colors.red, fontSize: 11),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final idStr = _chassisIdController.text.trim();
                            if (idStr.isEmpty) {
                              setState(() => _chassisError = 'Chassis ID is required.');
                              return;
                            }
                            final parsedId = int.tryParse(idStr);
                            if (parsedId == null) {
                              setState(() => _chassisError = 'Chassis ID must be a numeric integer.');
                              return;
                            }
                            if (_chassisNeRef == null) {
                              setState(() => _chassisError = 'Network Element Ref is required.');
                              return;
                            }
                            if (_chassisComponentRef == null) {
                              setState(() => _chassisError = 'Component Ref is required.');
                              return;
                            }
                            final newChassis = ContainedChassis(
                              chassisId: parsedId,
                              neRef: _chassisNeRef!,
                              componentRef: _chassisComponentRef!,
                            );
                            try {
                              InventoryLocationValidator.validateContainedChassis(newChassis, _editingContainedChassis);
                              setState(() {
                                _editingContainedChassis.add(newChassis);
                                _chassisIdController.clear();
                                _chassisNeRef = null;
                                _chassisComponentRef = null;
                                _chassisError = null;
                              });
                            } catch (e) {
                              setState(() => _chassisError = e.toString().replaceFirst('FormatException: ', ''));
                            }
                          },
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add to Location', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: _submitInventoryLocationSave,
                        child: Text(_isEditingLocation ? 'Update Location' : 'Create Location'),
                      ),
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

  Widget _buildInventoryLocationListPane(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final treeNodes = _buildFlattenedTree();

    final Widget listContent = treeNodes.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No locations registered.'),
            ),
          )
        : ListView.separated(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: treeNodes.length,
            separatorBuilder: (context, index) => const Divider(height: 8),
            itemBuilder: (context, index) {
              final nodeData = treeNodes[index];
              final InventoryLocation loc = nodeData['location'];
              final int depth = nodeData['depth'];

              IconData icon;
              Color color;
              switch (loc.type.toLowerCase()) {
                case 'site':
                  icon = Icons.business;
                  color = Colors.teal;
                  break;
                case 'building':
                  icon = Icons.apartment;
                  color = Colors.blue;
                  break;
                case 'floor':
                  icon = Icons.layers;
                  color = Colors.indigo;
                  break;
                case 'room':
                  icon = Icons.meeting_room;
                  color = Colors.purple;
                  break;
                case 'rackspace':
                  icon = Icons.dns;
                  color = Colors.orange;
                  break;
                default:
                  icon = Icons.place;
                  color = Colors.grey;
                  break;
              }

              final bool expired = loc.isExpired;

              return Padding(
                padding: EdgeInsets.only(left: depth * 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      depth == 0 ? icon : Icons.subdirectory_arrow_right,
                      color: expired ? Colors.grey : color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    if (depth > 0) ...[
                      Icon(icon, color: expired ? Colors.grey : color, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  loc.id,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    decoration: expired ? TextDecoration.lineThrough : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (expired ? Colors.red : Colors.green).withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: (expired ? Colors.red : Colors.green).withValues(alpha: 0.4),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  expired ? 'EXPIRED' : 'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: expired ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Type: ${loc.type} | Parent: ${loc.parent ?? "None"}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Recorded: ${loc.timestamp.toIso8601String().substring(0, 19).replaceFirst("T", " ")}'
                            '${loc.validUntil != null ? ' | Valid Until: ${loc.validUntil!.toIso8601String().substring(0, 19).replaceFirst("T", " ")}' : ''}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          if (loc.physicalAddress != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Colors.blueGrey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    loc.physicalAddress!.toPostalLabel(),
                                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Map Link: ${loc.physicalAddress!.toMapSearchQuery()}'),
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View Map',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (loc.containedChassis.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...loc.containedChassis.map((chassis) {
                              final ne = _networkInventoryService.getNetworkElement(chassis.neRef);
                              final hasNe = ne != null;
                              final hasComp = ne != null && ne.componentIds.contains(chassis.componentRef);
                              final bool isDangling = !hasNe || !hasComp;

                              return Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.dns_outlined, size: 12, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Chassis #${chassis.chassisId} (NE: ${chassis.neRef}, Component: ${chassis.componentRef})',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDangling ? Colors.red : Colors.blueGrey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isDangling) ...[
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: const Text(
                                            '⚠️ Dangling Pointer: Invalid NE/Component Reference',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      tooltip: 'Edit Location',
                      onPressed: () {
                        setState(() {
                          _selectedInventoryLocation = loc;
                          _locationIdController.text = loc.id;
                          _locationTypeController.text = loc.type;
                          _selectedLocationParentId = loc.parent;
                          _locationTimestampController.text =
                              loc.timestamp.toIso8601String().substring(0, 19).replaceFirst("T", " ");
                          _locationValidUntilController.text = loc.validUntil != null
                              ? loc.validUntil!.toIso8601String().substring(0, 19).replaceFirst("T", " ")
                              : '';
                          if (loc.physicalAddress != null) {
                            _locationAddressController.text = loc.physicalAddress!.address;
                            _locationPostalCodeController.text = loc.physicalAddress!.postalCode;
                            _locationStateController.text = loc.physicalAddress!.state;
                            _locationCityController.text = loc.physicalAddress!.city;
                            _locationCountryCodeController.text = loc.physicalAddress!.countryCode;
                          } else {
                            _locationAddressController.clear();
                            _locationPostalCodeController.clear();
                            _locationStateController.clear();
                            _locationCityController.clear();
                            _locationCountryCodeController.clear();
                          }
                          _editingContainedChassis = List<ContainedChassis>.from(loc.containedChassis);
                          _isEditingLocation = true;
                          _locationFormError = null;
                          _locationCountryCodeError = null;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          );

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YANG Hierarchical Locations Registry',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            isDesktop ? Expanded(child: listContent) : listContent,
          ],
        ),
      ),
    );
  }
}

class SparklineWidget extends StatelessWidget {
  final List<BigInt> history;
  final Color color;

  const SparklineWidget({
    super.key,
    required this.history,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 30,
      child: CustomPaint(
        painter: _SparklinePainter(history, color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<BigInt> history;
  final Color color;

  _SparklinePainter(this.history, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Find min and max values to normalize
    BigInt minVal = history.reduce((a, b) => a < b ? a : b);
    BigInt maxVal = history.reduce((a, b) => a > b ? a : b);
    
    // Prevent division by zero if all values are equal
    double range = (maxVal - minVal).toDouble();
    if (range == 0.0) range = 1.0;

    final dx = size.width / (history.length - 1);
    
    for (int i = 0; i < history.length; i++) {
      final double x = i * dx;
      final double normalizedY = (history[i] - minVal).toDouble() / range;
      final double y = size.height - (normalizedY * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.history != history || oldDelegate.color != color;
}

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
                  
                  // Mock some server modules
                  bool isFilled = false;
                  Color moduleColor = Colors.transparent;
                  String moduleLabel = '';
                  IconData? moduleIcon;

                  if (uIndex == 1 || uIndex == 2) {
                    isFilled = true;
                    moduleColor = Colors.amber.withValues(alpha: 0.2);
                    moduleLabel = 'Core Switch (2U)';
                    moduleIcon = Icons.settings_ethernet;
                  } else if (uIndex == 5) {
                    isFilled = true;
                    moduleColor = Colors.purple.withValues(alpha: 0.2);
                    moduleLabel = 'Quantum KMS (1U)';
                    moduleIcon = Icons.vpn_key;
                  } else if (uIndex >= 10 && uIndex <= 13) {
                    isFilled = true;
                    moduleColor = Colors.teal.withValues(alpha: 0.2);
                    moduleLabel = uIndex == 13 ? 'Cognitive Compute Node (4U)' : '';
                    moduleIcon = uIndex == 13 ? Icons.dns : null;
                  } else if (uIndex == 20 || uIndex == 21) {
                    isFilled = true;
                    moduleColor = Colors.blue.withValues(alpha: 0.2);
                    moduleLabel = uIndex == 21 ? 'Primary Power Unit (2U)' : '';
                    moduleIcon = uIndex == 21 ? Icons.power : null;
                  }

                  return Container(
                    height: 24,
                    margin: const EdgeInsets.symmetric(vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isFilled ? moduleColor : slotBg,
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
                          child: Text(
                            'U$uIndex',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : Colors.black54,
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
          const SizedBox(height: 12),
          // Dimensions tags
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildDimBadge('H: ${rack.height}mm'),
              _buildDimBadge('W: ${rack.width}mm'),
              _buildDimBadge('D: ${rack.depth}mm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDimBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
