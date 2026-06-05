import 'package:cogctl_ux/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/features/software_configuration/domain/inventory_type_reference.dart';
import 'package:cogctl_ux/features/software_configuration/domain/repositories/i_types_references_repository.dart';
import 'package:cogctl_ux/features/infrastructure/domain/repositories/i_network_inventory_repository.dart';
import 'package:cogctl_ux/features/software_configuration/presentation/cubit/types_references_cubit.dart';
import 'package:cogctl_ux/features/software_configuration/presentation/cubit/types_references_state.dart';

class TypesReferencesScreen extends StatelessWidget {
  const TypesReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TypesReferencesCubit(
        sl<ITypesReferencesRepository>(),
      ),
      child: const _TypesReferencesView(),
    );
  }
}

class _TypesReferencesView extends StatefulWidget {
  const _TypesReferencesView();

  @override
  State<_TypesReferencesView> createState() => _TypesReferencesViewState();
}

class _TypesReferencesViewState extends State<_TypesReferencesView> {
  final _typesRefFormKey = GlobalKey<FormState>();
  final _typesRefIdController = TextEditingController();

  String _selectedTypesRefType = 'ne-ref';
  String? _selectedTypesRefNe;
  String? _selectedTypesRefTarget;
  String? _typesRefFormError;

  @override
  void initState() {
    super.initState();
    _initializeDropdowns();
  }

  void _initializeDropdowns() {
    final neRepo = sl<INetworkInventoryRepository>();
    final neList = neRepo.getNetworkElements();
    if (neList.isNotEmpty) {
      _selectedTypesRefNe = neList.first.neId;
      _updateTargetDropdownOptions();
    }
  }

  void _updateTargetDropdownOptions() {
    final neRepo = sl<INetworkInventoryRepository>();
    if (_selectedTypesRefNe != null) {
      final ne = neRepo.getNetworkElement(_selectedTypesRefNe!);
      final components = ne?.componentIds ?? [];
      if (components.isNotEmpty) {
        _selectedTypesRefTarget = components.first;
      } else {
        _selectedTypesRefTarget = null;
      }
    } else {
      _selectedTypesRefTarget = null;
    }
  }

  @override
  void dispose() {
    _typesRefIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocConsumer<TypesReferencesCubit, TypesReferencesState>(
      listener: (context, state) {
        if (state.generalError != null) {
          setState(() {
            _typesRefFormError = state.generalError;
          });
        }
      },
      builder: (context, state) {
        return isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 12),
                  _buildSummary(theme, state),
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
                    const SizedBox(height: 12),
                    _buildSummary(theme, state),
                    const SizedBox(height: 24),
                    _buildFormCard(theme, state),
                    const SizedBox(height: 24),
                    _buildListPane(theme, state),
                  ],
                ),
              );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'YANG Types & References',
              style: TextStyle(
                fontSize: 24,
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
                'ACTIVE',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and validate references mapping (ne-ref, component-ref, port-ref) against network inventory.',
          style: TextStyle(
            color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(ThemeData theme, TypesReferencesState state) {
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    int total = state.references.length;
    int valid = state.references.where((r) => context.read<TypesReferencesCubit>().validateReference(r) == 'Valid').length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'Total References', '$total', Icons.link, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'Valid References', '$valid', Icons.check_circle_outline, Colors.green),
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

  Widget _buildFormCard(ThemeData theme, TypesReferencesState state) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    final neRepo = sl<INetworkInventoryRepository>();
    final neList = neRepo.getNetworkElements();
    final ne = _selectedTypesRefNe != null 
        ? neRepo.getNetworkElement(_selectedTypesRefNe!) 
        : null;
    final components = ne?.componentIds ?? [];

    return Card(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: borderSide,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _typesRefFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure Type Reference',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // ID Field
              TextFormField(
                key: const ValueKey('types-ref-id-field'),
                controller: _typesRefIdController,
                decoration: const InputDecoration(
                  labelText: 'Reference Config ID (id)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Reference Type Dropdown
              DropdownButtonFormField<String>(
                key: const ValueKey('types-ref-type-dropdown'),
                value: _selectedTypesRefType,
                decoration: const InputDecoration(
                  labelText: 'Reference Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'ne-ref', child: Text('ne-ref (Network Element)')),
                  DropdownMenuItem(value: 'component-ref', child: Text('component-ref (Component)')),
                  DropdownMenuItem(value: 'port-ref', child: Text('port-ref (Port Component)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedTypesRefType = val;
                      _typesRefFormError = null;
                      _updateTargetDropdownOptions();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Network Element Dropdown
              DropdownButtonFormField<String>(
                key: const ValueKey('types-ref-ne-dropdown'),
                value: _selectedTypesRefNe,
                decoration: const InputDecoration(
                  labelText: 'Referenced Network Element (ne-ref)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: neList.map((e) {
                  return DropdownMenuItem(value: e.neId, child: Text(e.neId));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedTypesRefNe = val;
                      _typesRefFormError = null;
                      _updateTargetDropdownOptions();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Target Component Dropdown (Visible only if component-ref or port-ref)
              if (_selectedTypesRefType != 'ne-ref') ...[
                DropdownButtonFormField<String>(
                  key: const ValueKey('types-ref-target-dropdown'),
                  value: _selectedTypesRefTarget,
                  decoration: const InputDecoration(
                    labelText: 'Referenced Target Component (target-ref)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: components.map((compId) {
                    final compClass = sl<ITypesReferencesRepository>().getComponentClass(compId);
                    return DropdownMenuItem(
                      value: compId,
                      child: Text('$compId ($compClass)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedTypesRefTarget = val;
                        _typesRefFormError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Error banner
              if (_typesRefFormError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _typesRefFormError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  key: const ValueKey('create-reference-button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    final idText = _typesRefIdController.text.trim();
                    if (idText.isEmpty) {
                      setState(() {
                        _typesRefFormError = 'ID is required';
                      });
                      return;
                    }
                    
                    final ref = MockInventoryTypeReference(
                      id: idText,
                      referenceType: _selectedTypesRefType,
                      neRef: _selectedTypesRefNe ?? '',
                      targetRef: (_selectedTypesRefType != 'ne-ref') ? _selectedTypesRefTarget : null,
                    );
                    final validationResult = context.read<TypesReferencesCubit>().validateReference(ref);
                    if (validationResult != 'Valid') {
                      setState(() {
                        _typesRefFormError = validationResult;
                      });
                      return;
                    }
                    // Success
                    context.read<TypesReferencesCubit>().addReference(ref);
                    // Check if state has error
                    final stateAfter = context.read<TypesReferencesCubit>().state;
                    if (stateAfter.generalError == null) {
                      setState(() {
                        _typesRefFormError = null;
                        _typesRefIdController.clear();
                      });
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Successfully created reference configuration')),
                      );
                    }
                  },
                  child: const Text('Create Reference'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListPane(ThemeData theme, TypesReferencesState state) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    return Card(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: borderSide,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Reference Configurations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (state.references.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text('No reference configurations configured.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.references.length,
                separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white10 : Colors.black12),
                itemBuilder: (context, index) {
                  final ref = state.references[index];
                  final validation = context.read<TypesReferencesCubit>().validateReference(ref);
                  final isValid = validation == 'Valid';

                  return Row(
                    children: [
                      // Status Icon
                      Icon(
                        isValid ? Icons.check_circle : Icons.error_outline,
                        color: isValid ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ref.id,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Type: ${ref.referenceType} | NE: ${ref.neRef}' +
                                  (ref.targetRef != null ? ' | Target: ${ref.targetRef}' : ''),
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                            ),
                            if (!isValid) ...[
                              const SizedBox(height: 2),
                              Text(
                                validation,
                                style: const TextStyle(color: Colors.red, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Actions
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          context.read<TypesReferencesCubit>().deleteReference(ref.id);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Successfully deleted reference configuration')),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
