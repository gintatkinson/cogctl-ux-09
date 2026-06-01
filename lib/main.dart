import 'package:flutter/material.dart' hide Velocity;
import 'dart:math';
import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    _refreshList();

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
    _expiryUpdateTimer?.cancel();
    super.dispose();
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
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
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
}
