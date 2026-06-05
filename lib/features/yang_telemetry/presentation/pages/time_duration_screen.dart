import 'package:cogctl_ux/widgets/dashboard_header.dart';
import 'package:cogctl_ux/utils/snackbar_utils.dart';
import 'package:cogctl_ux/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/time_duration.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_time_duration_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/time_duration_cubit.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/time_duration_state.dart';

class TimeDurationScreen extends StatelessWidget {
  const TimeDurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimeDurationCubit(sl<ITimeDurationRepository>()),
      child: const _TimeDurationView(),
    );
  }
}

class _TimeDurationView extends StatefulWidget {
  const _TimeDurationView();

  @override
  State<_TimeDurationView> createState() => _TimeDurationViewState();
}

class _TimeDurationViewState extends State<_TimeDurationView> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _simulateWrapAround(TimeDurationCubit cubit, YangTimeDurationReference? selectedNode) {
    if (selectedNode == null) return;
    if (selectedNode.type != YangTimeDurationType.timeticks) return;

    _valueController.text = '0';
    cubit.updateValue(selectedNode.id, '0');
    showSuccessSnackBar(context, 'Successfully updated ${selectedNode.name} to 0');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocConsumer<TimeDurationCubit, TimeDurationState>(
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
                  const DashboardHeader(title: 'Time Durations Dashboard', badgeLabel: 'RFC 9911 Time-Duration Specs'),
                  const SizedBox(height: 16),
                  _buildTimeDurationSummary(theme, state.nodes),
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
                    const DashboardHeader(title: 'Time Durations Dashboard', badgeLabel: 'RFC 9911 Time-Duration Specs'),
                    const SizedBox(height: 16),
                    _buildTimeDurationSummary(theme, state.nodes),
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



  Widget _buildTimeDurationSummary(ThemeData theme, List<YangTimeDurationReference> nodes) {
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    int total = nodes.length;
    int ticks = nodes.where((n) => n.type == YangTimeDurationType.timeticks || n.type == YangTimeDurationType.timestamp).length;
    int stdDurations = nodes.where((n) => n.type != YangTimeDurationType.timeticks && n.type != YangTimeDurationType.timestamp).length;

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

  Widget _buildFormCard(ThemeData theme, TimeDurationState state) {
    final cardBg = cardBackground(theme);

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
                  'Update Time Duration / Ticks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Select Node Dropdown
                DropdownButtonFormField<YangTimeDurationReference>(
                  isExpanded: true,
                  value: state.selectedNode,
                  decoration: const InputDecoration(
                    labelText: 'Target Node',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: cardBg,
                  items: state.nodes.map((node) {
                    return DropdownMenuItem<YangTimeDurationReference>(
                      value: node,
                      child: Text(
                        '${node.name} (${node.type.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (YangTimeDurationReference? val) {
                    context.read<TimeDurationCubit>().selectNode(val);
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
                         if (state.selectedNode!.associatedNodeId != null) ...[
                           const SizedBox(height: 4),
                           Text(
                             'Associated Ticks: ${state.selectedNode!.associatedNodeId}',
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
                      context.read<TimeDurationCubit>().validateValue(val, state.selectedNode!.type);
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
                        onPressed: () {
                          if (state.selectedNode != null) {
                            context.read<TimeDurationCubit>().updateValue(
                              state.selectedNode!.id,
                              _valueController.text,
                            );
                            showSuccessSnackBar(context, 'Successfully updated ${state.selectedNode!.name} to ${_valueController.text}');
                          }
                        },
                        child: const Text('Update Value'),
                      ),
                    ),
                    if (state.selectedNode?.type == YangTimeDurationType.timeticks) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: () => _simulateWrapAround(context.read<TimeDurationCubit>(), state.selectedNode),
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

  Widget _buildListPane(ThemeData theme, TimeDurationState state) {
    final cardBg = cardBackground(theme);
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
                      context.read<TimeDurationCubit>().selectNode(node);
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
}
