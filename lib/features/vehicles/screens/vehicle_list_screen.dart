import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) { if (mounted) setState(() => _loading = false); return; }
    try {
      final list = await VehicleService().getMyVehicles(userId);
      if (mounted) setState(() { _vehicles = list; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _openForm({VehicleModel? vehicle}) {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _VehicleFormSheet(userId: userId, vehicle: vehicle, onSaved: () { Navigator.pop(context); _load(); }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Vehículos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No tienes vehículos registrados', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Agregar vehículo')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _vehicles.length,
                  itemBuilder: (_, i) {
                    final v = _vehicles[i];
                    return GlassCard(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: v.photoUrl != null ? NetworkImage(v.photoUrl!) : null,
                          child: v.photoUrl == null
                              ? Text(v.brand.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text('${v.brand} ${v.model}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('${v.plate}  ·  ${v.manufactureYear}  ·  ${v.color}'),
                            if (v.notes != null) Text(v.notes!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 10, color: v.isActive ? Colors.green : Colors.grey),
                            const SizedBox(width: 4),
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openForm(vehicle: v)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ── Formulario ──────────────────────────────────────────────

class _VehicleFormSheet extends StatefulWidget {
  final int userId;
  final VehicleModel? vehicle;
  final VoidCallback onSaved;
  const _VehicleFormSheet({required this.userId, this.vehicle, required this.onSaved});
  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  late final TextEditingController _plateCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _notesCtrl;
  XFile? _photoFile;
  bool _isLoading = false;
  final _picker = ImagePicker();
  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _plateCtrl = TextEditingController(text: widget.vehicle?.plate ?? '');
    _brandCtrl = TextEditingController(text: widget.vehicle?.brand ?? '');
    _modelCtrl = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearCtrl = TextEditingController(text: widget.vehicle?.manufactureYear.toString() ?? '');
    _colorCtrl = TextEditingController(text: widget.vehicle?.color ?? '');
    _notesCtrl = TextEditingController(text: widget.vehicle?.notes ?? '');
  }

  @override
  void dispose() {
    _plateCtrl.dispose(); _brandCtrl.dispose(); _modelCtrl.dispose();
    _yearCtrl.dispose(); _colorCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (file != null) setState(() => _photoFile = file);
  }

  Future<void> _save() async {
    if (_plateCtrl.text.trim().isEmpty || _brandCtrl.text.trim().isEmpty) {
      AppToast.warning(context, message: 'Completa placa y marca');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final svc = VehicleService();
      final plate = _plateCtrl.text.trim();
      final brand = _brandCtrl.text.trim();
      final model = _modelCtrl.text.trim();
      final year = int.tryParse(_yearCtrl.text.trim()) ?? 2020;
      final color = _colorCtrl.text.trim();
      final notes = _notesCtrl.text.trim();

      if (_isEditing) {
        await svc.updateVehicle(widget.vehicle!.id, {
          'plate': plate, 'brand': brand, 'model': model,
          'manufacture_year': year, 'color': color,
          if (notes.isNotEmpty) 'notes': notes,
        });
      } else {
        await svc.createVehicle(
          userId: widget.userId, plate: plate, brand: brand,
          model: model, manufactureYear: year, color: color,
        );
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); AppToast.error(context, message: e.toString().replaceFirst('Exception: ', '')); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Expanded(child: Text(_isEditing ? 'Editar vehículo' : 'Agregar vehículo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),

          // Photo
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade400)),
              child: _photoFile != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_photoFile!.path), fit: BoxFit.cover))
                  : widget.vehicle?.photoUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.vehicle!.photoUrl!, fit: BoxFit.cover))
                      : const Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),

          // Fields grid
          CustomInputField(label: 'Placa', controller: _plateCtrl),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: CustomInputField(label: 'Marca', controller: _brandCtrl)),
              const SizedBox(width: 12),
              Expanded(child: CustomInputField(label: 'Modelo', controller: _modelCtrl)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: CustomInputField(label: 'Año', controller: _yearCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: CustomInputField(label: 'Color', controller: _colorCtrl)),
            ],
          ),
          const SizedBox(height: 10),
          CustomInputField(label: 'Observaciones', controller: _notesCtrl),
          const SizedBox(height: 20),
          CustomFilledButton(text: _isEditing ? 'Actualizar' : 'Guardar', isLoading: _isLoading, onPressed: _save),
        ],
      ),
    );
  }
}
