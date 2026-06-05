import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cogctl_ux/features/geo_location/presentation/pages/geo_location_screen.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/pages/counter_gauge_screen.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/pages/identifiers_references_screen.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/pages/date_time_screen.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/pages/time_duration_screen.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/pages/address_tag_screen.dart';
import 'package:cogctl_ux/features/infrastructure/presentation/pages/inventory_location_screen.dart';
import 'package:cogctl_ux/features/infrastructure/presentation/pages/equipment_racks_screen.dart';
import 'package:cogctl_ux/features/software_configuration/presentation/pages/types_references_screen.dart';
import 'package:cogctl_ux/features/software_configuration/presentation/pages/software_manufacturer_screen.dart';
import 'package:cogctl_ux/core/routing/main_shell.dart';

GoRouter createRouter({
  required ThemeMode Function() currentThemeMode,
  required ValueChanged<ThemeMode> onThemeChanged,
}) {
  return GoRouter(
    initialLocation: '/reference-frames',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(
            currentThemeMode: currentThemeMode(),
            onThemeChanged: onThemeChanged,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/reference-frames',
            builder: (context, state) => const GeoLocationScreen(),
          ),
          GoRoute(
            path: '/counters-gauges',
            builder: (context, state) => const CounterGaugeScreen(),
          ),
          GoRoute(
            path: '/identifiers-references',
            builder: (context, state) => const IdentifiersReferencesScreen(),
          ),
          GoRoute(
            path: '/date-time',
            builder: (context, state) => const DateTimeScreen(),
          ),
          GoRoute(
            path: '/time-durations',
            builder: (context, state) => const TimeDurationScreen(),
          ),
          GoRoute(
            path: '/addresses-tags',
            builder: (context, state) => const AddressTagScreen(),
          ),
          GoRoute(
            path: '/inventory-locations',
            builder: (context, state) => const InventoryLocationScreen(),
          ),
          GoRoute(
            path: '/equipment-racks',
            builder: (context, state) => const EquipmentRacksScreen(),
          ),
          GoRoute(
            path: '/types-references',
            builder: (context, state) => const TypesReferencesScreen(),
          ),
          GoRoute(
            path: '/software-manufacturer',
            builder: (context, state) => const SoftwareManufacturerScreen(),
          ),
        ],
      ),
    ],
  );
}
