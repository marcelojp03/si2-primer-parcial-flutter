import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/core/models/incident_model.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';

class TechnicianHomeScreen extends ConsumerStatefulWidget {
  static const name = 'technician-home';
  const TechnicianHomeScreen({super.key});
  @override
  ConsumerState<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends ConsumerState<TechnicianHomeScreen> {
  List<AssignmentModel> _assignments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final list = await IncidentService().getTechnicianAssignments();
      if (mounted) setState(() { _assignments = list; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Servicios'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(child: Text(user?.fullName ?? '', style: const TextStyle(fontSize: 12))),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No tienes servicios asignados', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignments.length,
                  itemBuilder: (_, i) {
                    final a = _assignments[i];
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      onTap: () => context.push('/technician/assignment/${a.id}?incidentId=${a.incidentId}'),
                      child: ListTile(
                        title: Text('Incidente #${a.incidentId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: a.assignmentStatus == 'EN_CAMINO' ? Colors.orange.shade100 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(a.assignmentStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: a.assignmentStatus == 'EN_CAMINO' ? Colors.orange : Colors.grey)),
                                ),
                                if (a.estimatedCost != null) ...[
                                  const SizedBox(width: 12),
                                  Text('Bs. ${a.estimatedCost!.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
    );
  }
}
