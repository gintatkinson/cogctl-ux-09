import 'package:cogctl_ux/widgets/dashboard_header.dart';
import 'package:cogctl_ux/utils/snackbar_utils.dart';
import 'package:cogctl_ux/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/counter_gauge.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_counter_gauge_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/counter_gauge_cubit.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/counter_gauge_state.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/widgets/sparkline_widget.dart';

class CounterGaugeScreen extends StatelessWidget {
  const CounterGaugeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CounterGaugeCubit(sl<ICounterGaugeRepository>()),
      child: const _CounterGaugeView(),
    );
  }
}

class _CounterGaugeView extends StatefulWidget {
  const _CounterGaugeView();

  @override
  State<_CounterGaugeView> createState() => _CounterGaugeViewState();
}

class _CounterGaugeViewState extends State<_CounterGaugeView> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  bool _discontinuityChecked = false;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocConsumer<CounterGaugeCubit, CounterGaugeState>(
      listener: (context, state) {
        if (state.selectedNode != null && _valueController.text != state.selectedNode!.value.toString() && !FocusScope.of(context).hasFocus) {
          _valueController.text = state.selectedNode!.value.toString();
        }
      },
      builder: (context, state) {
        final content = isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(title: 'Counters & Gauges Dashboard', badgeLabel: 'RFC 9911 / ietf-yang-types'),
                  const SizedBox(height: 16),
                  _buildCountersGaugesSummary(theme, state.nodes),
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
                    const DashboardHeader(title: 'Counters & Gauges Dashboard', badgeLabel: 'RFC 9911 / ietf-yang-types'),
                    const SizedBox(height: 16),
                    _buildCountersGaugesSummary(theme, state.nodes),
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



  Widget _buildCountersGaugesSummary(ThemeData theme, List<YangCounterGauge> nodes) {
    final cardBg = cardBackground(theme);
    final borderSide = subtleBorder(theme);

    int total = nodes.length;
    int counters = nodes.where((n) => n.isCounter).length;
    int gauges = nodes.where((n) => n.isGauge).length;
    int zeroBased = nodes.where((n) => n.isZeroBased).length;
    int highUtil = nodes.where((n) => n.isGauge && n.utilization > 0.9).length;

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

  Widget _buildFormCard(ThemeData theme, CounterGaugeState state) {
    final cardBg = cardBackground(theme);

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
                'Update Numeric Value',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Select Node Dropdown
              DropdownButtonFormField<YangCounterGauge>(
                isExpanded: true,
                value: state.selectedNode,
                decoration: const InputDecoration(
                  labelText: 'Target Node',
                  border: OutlineInputBorder(),
                ),
                dropdownColor: cardBg,
                items: state.nodes.map((node) {
                  return DropdownMenuItem<YangCounterGauge>(
                    value: node,
                    child: Text(
                      '${node.name} (${node.type.name})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (YangCounterGauge? val) {
                  context.read<CounterGaugeCubit>().selectNode(val);
                  if (val != null) {
                    _valueController.text = val.value.toString();
                    setState(() {
                      _discontinuityChecked = false;
                    });
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
                        'Type: ${state.selectedNode!.type.name} (Max Limit: ${state.selectedNode!.maxLimit != null ? state.selectedNode!.maxLimit.toString() : 'None'})',
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
                  labelText: 'New Numeric Value',
                  helperText: 'Enter non-negative integer (supports 64-bit bounds)',
                  border: const OutlineInputBorder(),
                  errorText: state.valueError,
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  if (state.selectedNode != null) {
                    context.read<CounterGaugeCubit>().validateValue(val, state.selectedNode!.type);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Discontinuity switch (only for counters)
              if (state.selectedNode != null && state.selectedNode!.isCounter) ...[
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
                      onPressed: () {
                        if (state.selectedNode != null) {
                          final cubit = context.read<CounterGaugeCubit>();
                          final name = state.selectedNode!.name;
                          final newVal = _valueController.text;
                          cubit.updateValue(
                            state.selectedNode!.id,
                            newVal,
                            discontinuity: _discontinuityChecked,
                          );
                          if (cubit.state.valueError == null) {
                            showSuccessSnackBar(context, 'Successfully updated $name to $newVal');
                            setState(() {
                              _discontinuityChecked = false;
                            });
                          }
                        }
                      },
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
                      if (state.selectedNode != null) {
                        context.read<CounterGaugeCubit>().resetNode(state.selectedNode!.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reset ${state.selectedNode!.name} to zero (discontinuity signaled).'),
                            backgroundColor: theme.primaryColor,
                          ),
                        );
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
    );
  }

  Widget _buildListPane(ThemeData theme, CounterGaugeState state) {
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
                          context.read<CounterGaugeCubit>().selectNode(node);
                          _valueController.text = node.value.toString();
                          setState(() {
                            _discontinuityChecked = false;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Reset to 0',
                        onPressed: () {
                          context.read<CounterGaugeCubit>().resetNode(node.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reset ${node.name} to zero (discontinuity signaled).'),
                              backgroundColor: theme.primaryColor,
                            ),
                          );
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
}
