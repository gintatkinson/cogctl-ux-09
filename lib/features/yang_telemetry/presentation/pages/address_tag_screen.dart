import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/address_tag.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_address_tag_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/address_tag_cubit.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/address_tag_state.dart';

class AddressTagScreen extends StatelessWidget {
  const AddressTagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddressTagCubit(sl<IAddressTagRepository>()),
      child: const _AddressTagView(),
    );
  }
}

class _AddressTagView extends StatefulWidget {
  const _AddressTagView();

  @override
  State<_AddressTagView> createState() => _AddressTagViewState();
}

class _AddressTagViewState extends State<_AddressTagView> {
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

    return BlocConsumer<AddressTagCubit, AddressTagState>(
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
                  _buildAddressTagHeader(theme),
                  const SizedBox(height: 16),
                  _buildAddressTagSummary(theme, state.nodes),
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
                    _buildAddressTagHeader(theme),
                    const SizedBox(height: 16),
                    _buildAddressTagSummary(theme, state.nodes),
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

  Widget _buildAddressTagSummary(ThemeData theme, List<YangAddressTagReference> nodes) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = nodes.length;
    int addresses = nodes.where((n) => n.type == YangAddressTagType.physAddress || n.type == YangAddressTagType.macAddress || n.type == YangAddressTagType.dottedQuad).length;
    int tags = nodes.where((n) => n.type == YangAddressTagType.languageTag || n.type == YangAddressTagType.xpath10 || n.type == YangAddressTagType.uuid).length;

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

  Widget _buildFormCard(ThemeData theme, AddressTagState state) {
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
                const Text(
                  'Update Address / Identity Tag',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<YangAddressTagReference>(
                  isExpanded: true,
                  value: state.selectedNode,
                  decoration: const InputDecoration(
                    labelText: 'Target Node',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: cardBg,
                  items: state.nodes.map((node) {
                    return DropdownMenuItem<YangAddressTagReference>(
                      value: node,
                      child: Text(
                        '${node.name} (${node.type.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (YangAddressTagReference? val) {
                    context.read<AddressTagCubit>().selectNode(val);
                    if (val != null) {
                      _valueController.text = val.value;
                    }
                  },
                ),
                const SizedBox(height: 16),

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

                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: 'New Value',
                    helperText: state.selectedNode == null
                        ? 'Select a node'
                        : 'Type: ${state.selectedNode!.type.name}',
                    border: const OutlineInputBorder(),
                    errorText: state.valueError,
                  ),
                  onChanged: (val) {
                    if (state.selectedNode != null) {
                      context.read<AddressTagCubit>().validateValue(val, state.selectedNode!.type);
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
                        onPressed: () {
                          if (state.selectedNode != null) {
                            context.read<AddressTagCubit>().updateValue(
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

  Widget _buildListPane(ThemeData theme, AddressTagState state) {
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
                      context.read<AddressTagCubit>().selectNode(node);
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
}
