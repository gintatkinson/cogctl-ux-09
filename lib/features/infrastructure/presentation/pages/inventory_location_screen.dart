import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/features/infrastructure/domain/inventory_location.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_inventory_location_repository.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_network_inventory_repository.dart';
import 'package:cogctl_ux/features/infrastructure/presentation/cubit/inventory_location_cubit.dart';
import 'package:cogctl_ux/features/infrastructure/presentation/cubit/inventory_location_state.dart';

class InventoryLocationScreen extends StatelessWidget {
  const InventoryLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryLocationCubit(
        sl<IInventoryLocationRepository>(),
        sl<INetworkInventoryRepository>(),
      ),
      child: const _InventoryLocationView(),
    );
  }
}

class _InventoryLocationView extends StatefulWidget {
  const _InventoryLocationView();

  @override
  State<_InventoryLocationView> createState() => _InventoryLocationViewState();
}

class _InventoryLocationViewState extends State<_InventoryLocationView> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _typeController = TextEditingController();
  final _timestampController = TextEditingController();
  final _validUntilController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryCodeController = TextEditingController();

  final _chassisIdController = TextEditingController();
  final _newNeIdController = TextEditingController();
  final _newComponentIdController = TextEditingController();

  String? _selectedParentId;
  List<ContainedChassis> _editingContainedChassis = [];
  String? _chassisNeRef;
  String? _chassisComponentRef;
  String? _selectedNeForNewComponent;

  @override
  void dispose() {
    _idController.dispose();
    _typeController.dispose();
    _timestampController.dispose();
    _validUntilController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _countryCodeController.dispose();
    _chassisIdController.dispose();
    _newNeIdController.dispose();
    _newComponentIdController.dispose();
    super.dispose();
  }

  void _populateForm(InventoryLocation loc) {
    _idController.text = loc.id;
    _typeController.text = loc.type;
    _selectedParentId = loc.parent;
    _timestampController.text =
        loc.timestamp.toIso8601String().substring(0, 19).replaceFirst("T", " ");
    _validUntilController.text = loc.validUntil != null
        ? loc.validUntil!.toIso8601String().substring(0, 19).replaceFirst("T", " ")
        : '';
    if (loc.physicalAddress != null) {
      _addressController.text = loc.physicalAddress!.address;
      _postalCodeController.text = loc.physicalAddress!.postalCode;
      _stateController.text = loc.physicalAddress!.state;
      _cityController.text = loc.physicalAddress!.city;
      _countryCodeController.text = loc.physicalAddress!.countryCode;
    } else {
      _addressController.clear();
      _postalCodeController.clear();
      _stateController.clear();
      _cityController.clear();
      _countryCodeController.clear();
    }
    _editingContainedChassis = List<ContainedChassis>.from(loc.containedChassis);
  }

  void _clearForm() {
    _idController.clear();
    _typeController.clear();
    _timestampController.clear();
    _validUntilController.clear();
    _addressController.clear();
    _postalCodeController.clear();
    _stateController.clear();
    _cityController.clear();
    _countryCodeController.clear();
    _chassisIdController.clear();
    _editingContainedChassis = [];
    _chassisNeRef = null;
    _chassisComponentRef = null;
    _selectedParentId = null;
  }

  List<Map<String, dynamic>> _buildFlattenedTree(List<InventoryLocation> locations) {
    final Map<String?, List<InventoryLocation>> parentToChildren = {};
    for (final loc in locations) {
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

    final allIds = locations.map((l) => l.id).toSet();
    final roots = locations.where((l) => l.parent == null || !allIds.contains(l.parent)).toList();
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

    for (final loc in locations) {
      if (!visited.contains(loc.id)) {
        result.add({
          'location': loc,
          'depth': 0,
        });
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocConsumer<InventoryLocationCubit, InventoryLocationState>(
      listener: (context, state) {
        if (state.generalError == null && state.status == InventoryLocationStatus.success) {
          // Success update/add
        }
      },
      builder: (context, state) {
        final content = isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  _buildSummary(theme, state.locations),
                  const SizedBox(height: 24),
                  _buildNetworkInventoryManager(theme, state),
                  const SizedBox(height: 24),
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
                    _buildHeader(theme),
                    const SizedBox(height: 16),
                    _buildSummary(theme, state.locations),
                    const SizedBox(height: 24),
                    _buildNetworkInventoryManager(theme, state),
                    const SizedBox(height: 24),
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

  Widget _buildHeader(ThemeData theme) {
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

  Widget _buildSummary(ThemeData theme, List<InventoryLocation> locations) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = locations.length;
    int active = locations.where((l) => !l.isExpired).length;
    int expired = locations.where((l) => l.isExpired).length;

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

  Widget _buildNetworkInventoryManager(ThemeData theme, InventoryLocationState state) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

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
        initiallyExpanded: state.isNeManagerExpanded,
        onExpansionChanged: (val) {
          context.read<InventoryLocationCubit>().setNeManagerExpanded(val);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.neManagerError != null) ...[
                  Text(
                    state.neManagerError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
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
                        context.read<InventoryLocationCubit>().addNetworkElement(neId, []);
                        _newNeIdController.clear();
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
                if (state.networkElements.isEmpty)
                  const Text(
                    'No network elements in inventory.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  )
                else
                  ...state.networkElements.map((ne) {
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
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                      tooltip: 'Delete NE',
                                      onPressed: () {
                                        context.read<InventoryLocationCubit>().deleteNetworkElement(ne.neId);
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
                                      context.read<InventoryLocationCubit>().deleteComponent(ne.neId, comp);
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
                                      context.read<InventoryLocationCubit>().addComponent(ne.neId, compId);
                                      _newComponentIdController.clear();
                                      setState(() {
                                        _selectedNeForNewComponent = null;
                                      });
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

  Widget _buildFormCard(ThemeData theme, InventoryLocationState state) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    final potentialParents = state.locations.where((loc) {
      if (!state.isEditing || state.selectedLocation == null) return true;
      if (loc.id == state.selectedLocation!.id) return false;
      try {
        InventoryLocationValidator.detectCircularLoop(state.selectedLocation!.id, loc.id, state.locations);
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
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.isEditing ? 'Edit Location' : 'Create Location',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (state.isEditing)
                      TextButton(
                        onPressed: () {
                          context.read<InventoryLocationCubit>().setEditing(false);
                          context.read<InventoryLocationCubit>().selectLocation(null);
                          _clearForm();
                        },
                        child: const Text('Cancel Edit'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.generalError != null) ...[
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
                      state.generalError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                TextFormField(
                  controller: _idController,
                  enabled: !state.isEditing,
                  decoration: InputDecoration(
                    labelText: 'Location ID (Unique)',
                    border: const OutlineInputBorder(),
                    errorText: state.idError,
                  ),
                  onChanged: (val) => context.read<InventoryLocationCubit>().validateField('id', val),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(
                    labelText: 'Type (e.g. site, room, floor)',
                    border: const OutlineInputBorder(),
                    errorText: state.typeError,
                  ),
                  onChanged: (val) => context.read<InventoryLocationCubit>().validateField('type', val),
                ),
                const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                  key: const Key('parentLocationDropdown'),
                  isExpanded: true,
                  value: (potentialParents.any((p) => p.id == _selectedParentId)) ? _selectedParentId : null,
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
                      _selectedParentId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timestampController,
                  decoration: InputDecoration(
                    labelText: 'Record Timestamp',
                    helperText: 'Format: YYYY-MM-DD HH:MM:SS or ISO-8601',
                    border: const OutlineInputBorder(),
                    errorText: state.timestampError,
                  ),
                  onChanged: (val) => context.read<InventoryLocationCubit>().validateField('timestamp', val),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _validUntilController,
                  decoration: InputDecoration(
                    labelText: 'Valid Until (Optional Expiration)',
                    helperText: 'Format: YYYY-MM-DD HH:MM:SS or ISO-8601',
                    border: const OutlineInputBorder(),
                    errorText: state.validUntilError,
                  ),
                  onChanged: (val) => context.read<InventoryLocationCubit>().validateField('validUntil', val),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Physical Address (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
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
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
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
                        controller: _postalCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Postal/ZIP Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _countryCodeController,
                        decoration: InputDecoration(
                          labelText: 'Country Code (ISO-2)',
                          helperText: 'e.g. US, GB',
                          border: const OutlineInputBorder(),
                          errorText: state.countryCodeError,
                        ),
                        onChanged: (val) => context.read<InventoryLocationCubit>().validateField('countryCode', val),
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
                      TextFormField(
                        controller: _chassisIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Chassis ID',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('neRefDropdown_${_chassisNeRef ?? "none"}'),
                              value: _chassisNeRef,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Network Element Ref',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              dropdownColor: cardBg,
                              items: state.networkElements.map((ne) {
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
                              value: _chassisComponentRef,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Component Ref',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              dropdownColor: cardBg,
                              items: _chassisNeRef == null
                                  ? []
                                  : (state.networkElements
                                          .firstWhere((ne) => ne.neId == _chassisNeRef)
                                          .componentIds)
                                      .map((comp) {
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
                      if (state.chassisError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          state.chassisError!,
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chassis ID is required.')),
                              );
                              return;
                            }
                            final parsedId = int.tryParse(idStr);
                            if (parsedId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chassis ID must be a numeric integer.')),
                              );
                              return;
                            }
                            if (_chassisNeRef == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Network Element Ref is required.')),
                              );
                              return;
                            }
                            if (_chassisComponentRef == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Component Ref is required.')),
                              );
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
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceFirst('FormatException: ', ''))),
                              );
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
                        onPressed: () {
                          final address = _addressController.text.trim();
                          final postalCode = _postalCodeController.text.trim();
                          final stateStr = _stateController.text.trim();
                          final city = _cityController.text.trim();
                          final countryCode = _countryCodeController.text.trim();

                          PhysicalAddress? physicalAddress;
                          if (address.isNotEmpty || postalCode.isNotEmpty || stateStr.isNotEmpty || city.isNotEmpty || countryCode.isNotEmpty) {
                            physicalAddress = PhysicalAddress(
                              address: address,
                              postalCode: postalCode,
                              state: stateStr,
                              city: city,
                              countryCode: countryCode,
                            );
                          }

                           try {
                             final idVal = state.isEditing && state.selectedLocation != null
                                 ? state.selectedLocation!.id
                                 : _idController.text.trim();
                             final typeVal = _typeController.text.trim();
                             final timestampStr = _timestampController.text.trim();
                             final validUntilStr = _validUntilController.text.trim();
                             print('DEBUG ONDR: isEditing=${state.isEditing}, selectedLocation=${state.selectedLocation?.id}, timestampStr=$timestampStr, validUntilStr=$validUntilStr, idVal=$idVal, typeVal=$typeVal');

                             if (idVal.isEmpty) throw const FormatException('Location ID is required.');
                             if (typeVal.isEmpty) throw const FormatException('Location type is required.');
                             if (timestampStr.isEmpty) throw const FormatException('Timestamp is required.');
                             
                             DateTime.parse(timestampStr);
                             if (validUntilStr.isNotEmpty) {
                               DateTime.parse(validUntilStr);
                             }

                              bool success = false;
                              if (state.isEditing && state.selectedLocation != null) {
                                success = context.read<InventoryLocationCubit>().updateLocation(
                                  id: idVal,
                                  type: typeVal,
                                  parent: _selectedParentId,
                                  rawTimestamp: timestampStr,
                                  rawValidUntil: validUntilStr.isNotEmpty ? validUntilStr : null,
                                  physicalAddress: physicalAddress,
                                  containedChassis: _editingContainedChassis,
                                );
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Successfully updated location $idVal'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                success = context.read<InventoryLocationCubit>().addLocation(
                                  id: idVal,
                                  type: typeVal,
                                  parent: _selectedParentId,
                                  rawTimestamp: timestampStr,
                                  rawValidUntil: validUntilStr.isNotEmpty ? validUntilStr : null,
                                  physicalAddress: physicalAddress,
                                  containedChassis: _editingContainedChassis,
                                );
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Successfully added location $idVal'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                              if (success) {
                                _clearForm();
                                context.read<InventoryLocationCubit>().setEditing(false);
                                context.read<InventoryLocationCubit>().selectLocation(null);
                              }
                           } catch (e, stack) {
                             print('DEBUG EXCEPTION: $e\n$stack');
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text(e.toString().replaceFirst('FormatException: ', '')),
                                 backgroundColor: Colors.red,
                               ),
                             );
                           }
                        },
                        child: Text(state.isEditing ? 'Update Location' : 'Create Location'),
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

  Widget _buildListPane(ThemeData theme, InventoryLocationState state) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final treeNodes = _buildFlattenedTree(state.locations);

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
                              final ne = state.networkElements.any((e) => e.neId == chassis.neRef)
                                  ? state.networkElements.firstWhere((e) => e.neId == chassis.neRef)
                                  : null;
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
                        context.read<InventoryLocationCubit>().selectLocation(loc);
                        context.read<InventoryLocationCubit>().setEditing(true);
                        _populateForm(loc);
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
