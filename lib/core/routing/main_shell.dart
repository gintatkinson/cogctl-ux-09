import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainShell({
    super.key,
    required this.child,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isDrawerCollapsed = false;

  String _getTitleForRoute(String path) {
    if (path.startsWith('/reference-frames')) {
      return 'RFC 9179 Geo-Location Specs';
    } else if (path.startsWith('/counters-gauges')) {
      return 'RFC 9911 Counters & Gauges';
    } else if (path.startsWith('/identifiers-references')) {
      return 'RFC 9911 Identifiers & Refs';
    } else if (path.startsWith('/date-time')) {
      return 'RFC 9911 Date & Time Types';
    } else if (path.startsWith('/time-durations')) {
      return 'RFC 9911 Time Durations';
    } else if (path.startsWith('/addresses-tags')) {
      return 'RFC 9911 Addresses & Tags';
    } else if (path.startsWith('/equipment-racks')) {
      return 'Equipment Racks Specs';
    } else {
      return 'IETF NI-Location Hierarchies';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final theme = Theme.of(context);
    
    // Get the current location path
    final GoRouterState routerState = GoRouterState.of(context);
    final currentPath = routerState.uri.path;
    final headerTitle = _getTitleForRoute(currentPath);

    return Scaffold(
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
                    headerTitle,
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              )
            : Text(
                headerTitle,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
              ),
        actions: [
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
                child: _buildSidebar(context, theme, currentPath, isDesktop),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) _buildSidebar(context, theme, currentPath, isDesktop),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, ThemeData theme, String currentPath, bool isDesktop) {
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
            context: context,
            icon: Icons.dashboard,
            label: 'Console Overview',
            isActive: false,
            onTap: () {},
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.language,
            label: 'Reference Frames',
            isActive: currentPath.startsWith('/reference-frames'),
            onTap: () {
              context.go('/reference-frames');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.analytics,
            label: 'Counters & Gauges',
            isActive: currentPath.startsWith('/counters-gauges'),
            onTap: () {
              context.go('/counters-gauges');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.fingerprint,
            label: 'Identifiers & Refs',
            isActive: currentPath.startsWith('/identifiers-references'),
            onTap: () {
              context.go('/identifiers-references');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.calendar_today,
            label: 'Date & Time Types',
            isActive: currentPath.startsWith('/date-time'),
            onTap: () {
              context.go('/date-time');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.hourglass_top,
            label: 'Time Durations',
            isActive: currentPath.startsWith('/time-durations'),
            onTap: () {
              context.go('/time-durations');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.tag,
            label: 'Addresses & Tags',
            isActive: currentPath.startsWith('/addresses-tags'),
            onTap: () {
              context.go('/addresses-tags');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.account_tree,
            label: 'Inventory Locations',
            isActive: currentPath.startsWith('/inventory-locations'),
            onTap: () {
              context.go('/inventory-locations');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.grid_view,
            label: 'Equipment Racks',
            isActive: currentPath.startsWith('/equipment-racks'),
            onTap: () {
              context.go('/equipment-racks');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.link,
            label: 'YANG Types & References',
            isActive: currentPath.startsWith('/types-references'),
            onTap: () {
              context.go('/types-references');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.settings_applications,
            label: 'Software & Mfg',
            isActive: currentPath.startsWith('/software-manufacturer'),
            onTap: () {
              context.go('/software-manufacturer');
              if (!isDesktop) Navigator.of(context).pop();
            },
          ),
          const Divider(height: 16),
          _buildSidebarItem(
            context: context,
            icon: Icons.settings_ethernet,
            label: 'Terrestrial & Mobile (Fiber)',
            isActive: false,
            onTap: () {},
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.waves,
            label: 'Submarine Networks (Subsea)',
            isActive: false,
            onTap: () {},
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.satellite_alt,
            label: 'Satellite & NTN Orbiters',
            isActive: false,
            onTap: () {},
          ),
          _buildSidebarItem(
            context: context,
            icon: Icons.rocket_launch,
            label: 'Deep Space Network (DSN)',
            isActive: false,
            onTap: () {},
          ),
          _buildSidebarItem(
            context: context,
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
    required BuildContext context,
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
}
