import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogctl_ux/core/di/service_locator.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/date_time.dart';
import 'package:cogctl_ux/features/yang_telemetry/domain/repositories/i_date_time_repository.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/date_time_cubit.dart';
import 'package:cogctl_ux/features/yang_telemetry/presentation/cubit/date_time_state.dart';

class DateTimeScreen extends StatelessWidget {
  const DateTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DateTimeCubit(sl<IDateTimeRepository>()),
      child: const _DateTimeView(),
    );
  }
}

class _DateTimeView extends StatefulWidget {
  const _DateTimeView();

  @override
  State<_DateTimeView> createState() => _DateTimeViewState();
}

class _DateTimeViewState extends State<_DateTimeView> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _setToCurrentTime(DateTimeCubit cubit, YangDateTimeReference? selectedNode) {
    if (selectedNode == null) return;
    
    final now = DateTime.now().toUtc();
    String formattedValue = '';
    
    switch (selectedNode.type) {
      case YangDateTimeType.dateAndTime:
        formattedValue = '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}T'
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}:'
            '${now.second.toString().padLeft(2, '0')}Z';
        break;
      case YangDateTimeType.date:
        formattedValue = '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}Z';
        break;
      case YangDateTimeType.dateNoZone:
        formattedValue = '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
        break;
      case YangDateTimeType.time:
        formattedValue = '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}:'
            '${now.second.toString().padLeft(2, '0')}Z';
        break;
      case YangDateTimeType.timeNoZone:
        formattedValue = '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}:'
            '${now.second.toString().padLeft(2, '0')}';
        break;
    }
    
    _valueController.text = formattedValue;
    cubit.validateValue(formattedValue, selectedNode.type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocConsumer<DateTimeCubit, DateTimeState>(
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
                  _buildDateTimeHeader(theme),
                  const SizedBox(height: 16),
                  _buildDateTimeSummary(theme, state.nodes),
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
                    _buildDateTimeHeader(theme),
                    const SizedBox(height: 16),
                    _buildDateTimeSummary(theme, state.nodes),
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

  Widget _buildDateTimeHeader(ThemeData theme) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Date & Time Types Dashboard',
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
            'RFC 9911 Date-Time Specs',
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

  Widget _buildDateTimeSummary(ThemeData theme, List<YangDateTimeReference> nodes) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2E30) : Colors.white;
    final borderSide = BorderSide(
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      width: 1,
    );

    int total = nodes.length;
    int datetimes = nodes.where((n) => n.type == YangDateTimeType.dateAndTime).length;
    int dates = nodes.where((n) => n.type == YangDateTimeType.date || n.type == YangDateTimeType.dateNoZone).length;
    int times = nodes.where((n) => n.type == YangDateTimeType.time || n.type == YangDateTimeType.timeNoZone).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TOTAL NODES', '$total', Icons.calendar_today, Colors.blue),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'DATE AND TIMES', '$datetimes', Icons.schedule, Colors.teal),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'DATES', '$dates', Icons.date_range, Colors.amber),
        _buildMiniStatusCard(theme, cardBg, borderSide, 'TIMES', '$times', Icons.hourglass_empty, Colors.purple),
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

  Widget _buildFormCard(ThemeData theme, DateTimeState state) {
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
                  'Update Date / Time String',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Select Node Dropdown
                DropdownButtonFormField<YangDateTimeReference>(
                  isExpanded: true,
                  value: state.selectedNode,
                  decoration: const InputDecoration(
                    labelText: 'Target Node',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: cardBg,
                  items: state.nodes.map((node) {
                    return DropdownMenuItem<YangDateTimeReference>(
                      value: node,
                      child: Text(
                        '${node.name} (${node.type.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (YangDateTimeReference? val) {
                    context.read<DateTimeCubit>().selectNode(val);
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
                    labelText: 'New Date/Time Value',
                    helperText: state.selectedNode == null
                        ? 'Select a node'
                        : "Format: ${state.selectedNode!.type == YangDateTimeType.dateAndTime ? 'YYYY-MM-DDTHH:MM:SS(Z|offset)' : (state.selectedNode!.type == YangDateTimeType.date ? 'YYYY-MM-DD(Z|offset)' : (state.selectedNode!.type == YangDateTimeType.dateNoZone ? 'YYYY-MM-DD' : (state.selectedNode!.type == YangDateTimeType.time ? 'HH:MM:SS(Z|offset)' : 'HH:MM:SS')))}",
                    border: const OutlineInputBorder(),
                    errorText: state.valueError,
                  ),
                  onChanged: (val) {
                    if (state.selectedNode != null) {
                      context.read<DateTimeCubit>().validateValue(val, state.selectedNode!.type);
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
                            context.read<DateTimeCubit>().updateValue(
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
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () => _setToCurrentTime(context.read<DateTimeCubit>(), state.selectedNode),
                      child: const Text('Set to Current'),
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

  Widget _buildListPane(ThemeData theme, DateTimeState state) {
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
                case YangDateTimeType.dateAndTime:
                  icon = Icons.schedule;
                  color = Colors.teal;
                  break;
                case YangDateTimeType.date:
                  icon = Icons.date_range;
                  color = Colors.amber[800] ?? Colors.amber;
                  break;
                case YangDateTimeType.dateNoZone:
                  icon = Icons.calendar_today;
                  color = Colors.blue;
                  break;
                case YangDateTimeType.time:
                  icon = Icons.hourglass_empty;
                  color = Colors.purple;
                  break;
                case YangDateTimeType.timeNoZone:
                  icon = Icons.access_time;
                  color = Colors.deepOrange;
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
                      context.read<DateTimeCubit>().selectNode(node);
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
              'YANG Date & Time Registry',
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
