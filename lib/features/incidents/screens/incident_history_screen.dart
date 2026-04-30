import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/core/models/incident_model.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/config/theme/app_theme.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';

class IncidentHistoryScreen extends ConsumerStatefulWidget {
  static const name = 'incident-history';

  const IncidentHistoryScreen({super.key});

  @override
  ConsumerState<IncidentHistoryScreen> createState() =>
      _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends ConsumerState<IncidentHistoryScreen> {
  List<IncidentModel> _incidents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final list = await IncidentService().getMyIncidents(userId);
      if (mounted)
        setState(() {
          _incidents = list;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Incidentes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _incidents.isEmpty
          ? const Center(child: Text('No hay incidentes registrados.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _incidents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final inc = _incidents[i];
                return GlassCard(
                  onTap: () => context.push('/incidents/${inc.id}/tracking'),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.incidentStatusColor(inc.statusLabel),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inc.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              inc.statusLabel,
                              style: TextStyle(
                                color: AppTheme.incidentStatusColor(
                                  inc.statusLabel,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
