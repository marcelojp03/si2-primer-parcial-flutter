import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si2_p1_mobile/core/models/vehicle_model.dart';
import 'package:si2_p1_mobile/core/services/vehicle_service.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_filled_button.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_input_field.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  static const name = 'vehicles';

  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  List<VehicleModel> _vehicles = [];
  bool _loading = true;

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
      final list = await VehicleService().getMyVehicles(userId);
      if (mounted)
        setState(() {
          _vehicles = list;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddVehicleSheet() {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _VehicleFormSheet(
        userId: userId,
        onSaved: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Vehículos')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleSheet,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text('No tienes vehículos registrados.'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showAddVehicleSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar vehículo'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final v = _vehicles[i];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(v.brand.substring(0, 1).toUpperCase()),
                    ),
                    title: Text('${v.brand} ${v.model}'),
                    subtitle: Text('${v.plate} · ${v.manufactureYear}'),
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: v.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _VehicleFormSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onSaved;

  const _VehicleFormSheet({required this.userId, required this.onSaved});

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await VehicleService().createVehicle(
        userId: widget.userId,
        plate: _plateCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        manufactureYear: int.tryParse(_yearCtrl.text.trim()) ?? 2020,
        color: _colorCtrl.text.trim(),
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Agregar vehículo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          CustomInputField(label: 'Placa', controller: _plateCtrl),
          const SizedBox(height: 12),
          CustomInputField(label: 'Marca', controller: _brandCtrl),
          const SizedBox(height: 12),
          CustomInputField(label: 'Modelo', controller: _modelCtrl),
          const SizedBox(height: 12),
          CustomInputField(
            label: 'Año',
            controller: _yearCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          CustomInputField(label: 'Color', controller: _colorCtrl),
          const SizedBox(height: 20),
          CustomFilledButton(
            text: 'Guardar',
            isLoading: _isLoading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
