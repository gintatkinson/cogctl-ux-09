import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/identifiers_references.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_identifiers_references_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/identifiers_references_cubit.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/identifiers_references_state.dart';

class IdentifiersReferencesScreen extends StatelessWidget {
  const IdentifiersReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => IdentifiersReferencesCubit(sl<IIdentifiersReferencesRepository>()),
      child: const _IdentifiersReferencesView(),
    );
  }
}

class _IdentifiersReferencesView extends StatefulWidget {
  const _IdentifiersReferencesView();

  @override
  State<_IdentifiersReferencesView> createState() => _IdentifiersReferencesViewState();
}

class _IdentifiersReferencesViewState extends State<_IdentifiersReferencesView> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocConsumer<IdentifiersReferencesCubit, IdentifiersReferencesState>(
      listener: (context, state) {
        if (state.selectedNode != null && _valueController.text != state.selectedNode!.value && !FocusScope.of(context).hasFocus) {
          _valueController.text = state.selectedNode!.value;
        }
      },
      builder: (context, state) {
        final content = isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentifiersReferencesHeader(theme),
                  const SizedBox(height: 16),
                  _buildIdentifiersReferencesSummary(theme, state.nodes),
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
                    _buildIdentifiersReferencesHeader(theme),
                    const SizedBox(height: 16),
                    _buildIdentifiersReferencesSummary(theme, state.nodes),
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

  Widget _buildIdentifiersReferencesSummary(ThemeData theme, List<YangIdentifierReference> nodes) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = nodes.length;
    int oids = nodes.where((n) => n.type == YangIdentifierType.objectIdentifier).length;
    int oids128 = nodes.where((n) => n.type == YangIdentifierType.objectIdentifier128).length;
    int yangIds = nodes.where((n) => n.type == YangIdentifierType.yangIdentifier).length;

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

  Widget _buildFormCard(ThemeData theme, IdentifiersReferencesState state) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
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
                value: state.selectedNode,
                decoration: const InputDecoration(
                  labelText: 'Target Node',
                  border: OutlineInputBorder(),
                ),
                dropdownColor: cardBg,
                items: state.nodes.map((node) {
                  return DropdownMenuItem<YangIdentifierReference>(
                    value: node,
                    child: Text(
                      '${node.name} (${node.type.name})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (YangIdentifierReference? val) {
                  context.read<IdentifiersReferencesCubit>().selectNode(val);
                  if (val != null) {
                    _valueController.text = val.value;
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description and Type Info
              if (state.selectedNode != null) ...[
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
                        state.selectedNode!.description,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${state.selectedNode!.type.name}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // New Value input field
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'New Identifier Value',
                  helperText: state.selectedNode?.type == YangIdentifierType.yangIdentifier
                      ? 'Valid YANG 1.1 identifier format (starts with letter/underscore)'
                      : 'Valid OID dotted-decimal sequence (e.g. 1.3.6.1.4.1)',
                  border: const OutlineInputBorder(),
                  errorText: state.valueError,
                ),
                onChanged: (val) {
                  if (state.selectedNode != null) {
                    context.read<IdentifiersReferencesCubit>().validateValue(val, state.selectedNode!.type);
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
                      onPressed: () {
                        if (state.selectedNode != null) {
                          context.read<IdentifiersReferencesCubit>().updateValue(
                            state.selectedNode!.id,
                            _valueController.text,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully updated ${state.selectedNode!.name} to ${_valueController.text}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text('Update Identifier'),
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

  Widget _buildListPane(ThemeData theme, IdentifiersReferencesState state) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final Widget listContent = state.nodes.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No nodes registered.'),
            ),
          )
        : ListView.separated(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: state.nodes.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final node = state.nodes[index];
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
                      context.read<IdentifiersReferencesCubit>().selectNode(node);
                      _valueController.text = node.value;
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
}
