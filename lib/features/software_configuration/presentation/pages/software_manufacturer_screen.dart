import 'package:cogctl_ux/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/features/software_configuration/domain/software_manufacturer.dart';
import 'package:cogctl_ux/features/software_configuration/domain/repositories/i_software_manufacturer_repository.dart';
import 'package:cogctl_ux/features/software_configuration/presentation/cubit/software_manufacturer_cubit.dart';
import 'package:cogctl_ux/features/software_configuration/presentation/cubit/software_manufacturer_state.dart';

class SoftwareManufacturerScreen extends StatelessWidget {
  const SoftwareManufacturerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SoftwareManufacturerCubit(
        sl<ISoftwareManufacturerRepository>(),
      ),
      child: const _SoftwareManufacturerView(),
    );
  }
}

class _SoftwareManufacturerView extends StatefulWidget {
  const _SoftwareManufacturerView();

  @override
  State<_SoftwareManufacturerView> createState() => _SoftwareManufacturerViewState();
}

class _SoftwareManufacturerViewState extends State<_SoftwareManufacturerView> {
  final _softwareMfgFormKey = GlobalKey<FormState>();

  final _smUuidController = TextEditingController();
  final _smNameController = TextEditingController();
  final _smAliasController = TextEditingController();
  final _smDescController = TextEditingController();
  final _smMfgNameController = TextEditingController();
  final _smProductNameController = TextEditingController();

  final _newSwNameController = TextEditingController();
  final _newSwRevController = TextEditingController();
  final _newPatchRevController = TextEditingController();

  String? _selectedSwNameForPatch;
  String? _smFormError;
  String? _loadedConfigId;

  @override
  void dispose() {
    _smUuidController.dispose();
    _smNameController.dispose();
    _smAliasController.dispose();
    _smDescController.dispose();
    _smMfgNameController.dispose();
    _smProductNameController.dispose();
    _newSwNameController.dispose();
    _newSwRevController.dispose();
    _newPatchRevController.dispose();
    super.dispose();
  }

  void _populateSelectedEntityData(MockSoftwareManufacturerConfig? config) {
    if (config == null) {
      _smUuidController.clear();
      _smNameController.clear();
      _smAliasController.clear();
      _smDescController.clear();
      _smMfgNameController.clear();
      _smProductNameController.clear();
      _selectedSwNameForPatch = null;
      _loadedConfigId = null;
      return;
    }

    _loadedConfigId = config.id;
    _smUuidController.text = config.uuid;
    _smNameController.text = config.name;
    _smAliasController.text = config.alias;
    _smDescController.text = config.description;
    _smMfgNameController.text = config.mfgName;
    _smProductNameController.text = config.productName;
    if (config.softwareRevisions.isNotEmpty) {
      if (_selectedSwNameForPatch == null || !config.softwareRevisions.any((s) => s.name == _selectedSwNameForPatch)) {
        _selectedSwNameForPatch = config.softwareRevisions.first.name;
      }
    } else {
      _selectedSwNameForPatch = null;
    }
  }

  void _saveSelectedEntityAttributes(MockSoftwareManufacturerConfig config) {
    final uuidVal = _smUuidController.text.trim();
    final nameVal = _smNameController.text.trim();
    final aliasVal = _smAliasController.text.trim();
    final descVal = _smDescController.text.trim();
    final mfgVal = _smMfgNameController.text.trim();
    final prodVal = _smProductNameController.text.trim();

    if (mfgVal.isEmpty) {
      setState(() {
        _smFormError = 'Manufacturer name is required';
      });
      return;
    }

    final updated = config.copyWith(
      uuid: uuidVal,
      name: nameVal,
      alias: aliasVal,
      description: descVal,
      mfgName: mfgVal,
      productName: prodVal,
    );

    final validationErr = context.read<SoftwareManufacturerCubit>().validateConfig(updated);
    if (validationErr != 'Valid') {
      setState(() {
        _smFormError = validationErr;
      });
      return;
    }

    context.read<SoftwareManufacturerCubit>().updateConfig(updated);
    final stateAfter = context.read<SoftwareManufacturerCubit>().state;
    if (stateAfter.generalError == null) {
      setState(() {
        _smFormError = null;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Common attributes saved successfully!')),
      );
    }
  }

  void _addSoftwareRevision(MockSoftwareManufacturerConfig config) {
    final nameVal = _newSwNameController.text.trim();
    final revVal = _newSwRevController.text.trim();

    if (nameVal.isEmpty) {
      setState(() {
        _smFormError = 'Software module name cannot be empty.';
      });
      return;
    }
    if (revVal.isEmpty) {
      setState(() {
        _smFormError = 'Software revision is required for module "$nameVal".';
      });
      return;
    }

    if (config.softwareRevisions.any((s) => s.name == nameVal)) {
      setState(() {
        _smFormError = 'Duplicate software module name "$nameVal".';
      });
      return;
    }

    final updatedRevs = List<MockSoftwareRevision>.from(config.softwareRevisions)
      ..add(MockSoftwareRevision(name: nameVal, revision: revVal, patches: []));

    final updated = config.copyWith(softwareRevisions: updatedRevs);

    context.read<SoftwareManufacturerCubit>().updateConfig(updated);
    final stateAfter = context.read<SoftwareManufacturerCubit>().state;
    if (stateAfter.generalError == null) {
      setState(() {
        _newSwNameController.clear();
        _newSwRevController.clear();
        _smFormError = null;
      });
    }
  }

  void _applySoftwarePatch(MockSoftwareManufacturerConfig config) {
    if (_selectedSwNameForPatch == null) return;
    final patchRevVal = _newPatchRevController.text.trim();

    if (patchRevVal.isEmpty) {
      setState(() {
        _smFormError = 'Patch revision cannot be empty.';
      });
      return;
    }

    final swIdx = config.softwareRevisions.indexWhere((s) => s.name == _selectedSwNameForPatch);
    if (swIdx == -1) return;

    final swRev = config.softwareRevisions[swIdx];
    if (swRev.patches.any((p) => p.revision == patchRevVal)) {
      setState(() {
        _smFormError = 'Duplicate patch revision "$patchRevVal" in module "${swRev.name}".';
      });
      return;
    }

    final updatedPatches = List<MockSoftwarePatch>.from(swRev.patches)
      ..add(MockSoftwarePatch(revision: patchRevVal));

    final updatedRevs = List<MockSoftwareRevision>.from(config.softwareRevisions);
    updatedRevs[swIdx] = swRev.copyWith(patches: updatedPatches);

    final updated = config.copyWith(softwareRevisions: updatedRevs);

    context.read<SoftwareManufacturerCubit>().updateConfig(updated);
    final stateAfter = context.read<SoftwareManufacturerCubit>().state;
    if (stateAfter.generalError == null) {
      setState(() {
        _newPatchRevController.clear();
        _smFormError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocConsumer<SoftwareManufacturerCubit, SoftwareManufacturerState>(
      listener: (context, state) {
        if (state.generalError != null) {
          setState(() {
            _smFormError = state.generalError;
          });
        }
        if (state.selectedConfig?.id != _loadedConfigId) {
          _populateSelectedEntityData(state.selectedConfig);
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
                  const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
        Text(
          'Software & Manufacturer Specs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.white : Colors.grey.shade900),
        ),
        const SizedBox(height: 4),
        Text(
          'YANG Network Inventory common entity attributes (uuid, name, alias, mfg-name, product-name, software-rev, and active patches).',
          style: TextStyle(fontSize: 12, color: theme.brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSummary(ThemeData theme, SoftwareManufacturerState state) {
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    int totalConfigs = state.configs.length;
    int neCount = state.configs.where((c) => c.targetType == 'Network Element').length;
    int componentCount = state.configs.where((c) => c.targetType == 'Component').length;
    int totalSoftwareRevs = state.configs.fold<int>(0, (sum, c) => sum + c.softwareRevisions.length);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'Total Configs', '$totalConfigs', Icons.settings, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'Network Elements', '$neCount', Icons.dns, Colors.teal),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'Components', '$componentCount', Icons.extension, Colors.orange),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'Software Modules', '$totalSoftwareRevs', Icons.folder_zip, Colors.purple),
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
        border: Border.all(color: border.color, width: 1),
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

  Widget _buildSMTextField({
    required TextEditingController controller,
    required String labelText,
    required Key key,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildFormCard(ThemeData theme, SoftwareManufacturerState state) {
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    if (state.selectedConfig == null) {
      return Card(
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: borderSide),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Select a configuration from the list to view/configure attributes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final config = state.selectedConfig!;
    final entityLabel = '${config.targetType}: ${config.targetId}';

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: borderSide),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _softwareMfgFormKey,
          child: ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Configure Attributes',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    entityLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (_smFormError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _smFormError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Basic Common Entity Attributes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700)),
              const SizedBox(height: 12),
              _buildSMTextField(controller: _smUuidController, labelText: 'UUID (uuid)', key: const ValueKey('sm_uuid_field')),
              const SizedBox(height: 12),
              _buildSMTextField(controller: _smNameController, labelText: 'Name (name)', key: const ValueKey('sm_name_field')),
              const SizedBox(height: 12),
              _buildSMTextField(controller: _smAliasController, labelText: 'Alias (alias)', key: const ValueKey('sm_alias_field')),
              const SizedBox(height: 12),
              _buildSMTextField(controller: _smDescController, labelText: 'Description (description)', key: const ValueKey('sm_desc_field')),
              const SizedBox(height: 20),
              Text('Manufacturer & Model Info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700)),
              const SizedBox(height: 12),
              _buildSMTextField(controller: _smMfgNameController, labelText: 'Manufacturer Name (mfg-name)', key: const ValueKey('sm_mfg_field')),
              const SizedBox(height: 12),
              _buildSMTextField(controller: _smProductNameController, labelText: 'Product Name (product-name)', key: const ValueKey('sm_product_field')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const ValueKey('sm_save_btn'),
                  onPressed: () => _saveSelectedEntityAttributes(config),
                  child: const Text('Save Attributes'),
                ),
              ),
              const Divider(height: 32),
              Text('Add Software Revision Module', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700)),
              const SizedBox(height: 12),
              _buildSMTextField(controller: _newSwNameController, labelText: 'Module Name (name - key)', key: const ValueKey('sm_sw_name_field')),
              const SizedBox(height: 12),
              _buildSMTextField(controller: _newSwRevController, labelText: 'Version Revision (revision)', key: const ValueKey('sm_sw_rev_field')),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const ValueKey('sm_add_sw_btn'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Software Revision'),
                  onPressed: () => _addSoftwareRevision(config),
                ),
              ),
              const Divider(height: 32),
              Text('Apply Software Patch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey('sm_sw_dropdown'),
                value: _selectedSwNameForPatch,
                decoration: const InputDecoration(
                  labelText: 'Select Software Module',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                dropdownColor: cardBg,
                items: [
                  if (config.softwareRevisions.isEmpty)
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('-- No Modules Available --', style: TextStyle(fontSize: 13)),
                    )
                  else
                    ...config.softwareRevisions.map((s) => DropdownMenuItem<String>(
                          value: s.name,
                          child: Text(s.name, style: const TextStyle(fontSize: 13)),
                        )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedSwNameForPatch = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildSMTextField(controller: _newPatchRevController, labelText: 'Patch Revision (revision)', key: const ValueKey('sm_patch_rev_field')),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const ValueKey('sm_apply_patch_btn'),
                  icon: const Icon(Icons.build, size: 16),
                  label: const Text('Apply Patch'),
                  onPressed: () => _applySoftwarePatch(config),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListPane(ThemeData theme, SoftwareManufacturerState state) {
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    final listContent = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.configs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final config = state.configs[index];
        final isSelected = state.selectedConfig?.id == config.id;

        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: theme.primaryColor.withValues(alpha: 0.1),
          title: Text(
            '${config.id} (${config.targetType})',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? theme.primaryColor : null),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mfg: ${config.mfgName} | Product: ${config.productName}'),
              const SizedBox(height: 4),
              if (config.softwareRevisions.isNotEmpty) ...[
                const Text('Software Revisions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ...config.softwareRevisions.map((rev) {
                  final patchesText = rev.patches.isEmpty
                      ? 'No patches'
                      : 'Patches: ${rev.patches.map((p) => p.revision).join(', ')}';
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 2),
                    child: Text('• ${rev.name} (${rev.revision}) [$patchesText]', style: const TextStyle(fontSize: 11)),
                  );
                }),
              ] else
                const Text('No software modules configured.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11)),
            ],
          ),
          onTap: () {
            context.read<SoftwareManufacturerCubit>().selectConfig(config);
          },
        );
      },
    );

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: borderSide),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configured Software & Mfg Attributes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            listContent,
          ],
        ),
      ),
    );
  }
}
