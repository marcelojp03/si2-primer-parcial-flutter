import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:si2_p1_mobile/core/models/local_incident_model.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/core/services/local_incident_repository.dart';
import 'package:si2_p1_mobile/core/services/vehicle_service.dart';
import 'package:si2_p1_mobile/core/models/vehicle_model.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_filled_button.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_input_field.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';

class NewIncidentScreen extends ConsumerStatefulWidget {
  static const name = 'new-incident';

  const NewIncidentScreen({super.key});

  @override
  ConsumerState<NewIncidentScreen> createState() => _NewIncidentScreenState();
}

class _NewIncidentScreenState extends ConsumerState<NewIncidentScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _isLoading = false;

  // Step 1 — Descripción
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Step 2 — Vehículo
  List<VehicleModel> _vehicles = [];
  VehicleModel? _selectedVehicle;

  // Step 3 — GPS
  Position? _position;

  // Step 4 — Evidencias
  XFile? _photo;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    try {
      final vehicles = await VehicleService().getMyVehicles(userId);
      if (mounted) setState(() => _vehicles = vehicles);
    } catch (_) {}
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted)
          AppToast.error(
            context,
            message: 'Permiso de GPS denegado permanentemente',
          );
        return;
      }
      setState(() => _isLoading = true);
      final pos = await Geolocator.getCurrentPosition();
      if (mounted)
        setState(() {
          _position = pos;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, message: 'Error al obtener ubicación');
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (img != null && mounted) setState(() => _photo = img);
  }

  Future<void> _submit() async {
    if (_selectedVehicle == null) {
      AppToast.warning(context, message: 'Selecciona un vehículo');
      return;
    }
    if (_position == null) {
      AppToast.warning(context, message: 'Obtén tu ubicación primero');
      return;
    }

    setState(() => _isLoading = true);
    final clientUserId = ref.read(authProvider).user?.id;
    if (clientUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Generar uuid_cliente para idempotencia offline
    final uuidCliente = const Uuid().v4();

    // Verificar conectividad
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((r) => r != ConnectivityResult.none);

    if (!isOnline) {
      // Modo offline: guardar en Hive con PENDIENTE_SYNC
      final draft = LocalIncidentModel(
        uuid: uuidCliente,
        title: _titleCtrl.text.trim(),
        descriptionText: _descCtrl.text.trim(),
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        vehicleId: _selectedVehicle!.id,
        syncStatus: 'PENDIENTE_SYNC',
      );
      await LocalIncidentRepository().save(draft);
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.info(
          context,
          message:
              'Sin conexión. Emergencia guardada. Se enviará al recuperar red.',
        );
        context.go('/home');
      }
      return;
    }

    try {
      final service = IncidentService();
      final incident = await service.createIncident(
        clientUserId: clientUserId,
        vehicleId: _selectedVehicle!.id,
        title: _titleCtrl.text.trim(),
        descriptionText: _descCtrl.text.trim(),
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        uuidCliente: uuidCliente,
      );

      if (_photo != null) {
        await service.uploadEvidence(incident.id, _photo!.path, 'IMAGE');
      }

      await service.analyzeIncident(incident.id);

      if (mounted) context.go('/incidents/${incident.id}/tracking');
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

  void _nextPage() {
    if (_page < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _page++);
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _page--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const steps = ['Descripción', 'Vehículo', 'Ubicación', 'Evidencias'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_page > 0) {
          _prevPage();
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva Emergencia'),
          leading: BackButton(
            onPressed: () {
              if (_page > 0) {
                _prevPage();
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Indicador de pasos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: List.generate(steps.length, (i) {
                  final isActive = i <= _page;
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (i < steps.length - 1) const SizedBox(width: 4),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Text(
              'Paso ${_page + 1}: ${steps[_page]}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Páginas
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepDescription(titleCtrl: _titleCtrl, descCtrl: _descCtrl),
                  _StepVehicle(
                    vehicles: _vehicles,
                    selected: _selectedVehicle,
                    onSelect: (v) => setState(() => _selectedVehicle = v),
                  ),
                  _StepLocation(
                    position: _position,
                    isLoading: _isLoading,
                    onGetLocation: _getLocation,
                  ),
                  _StepEvidences(photo: _photo, onPickPhoto: _pickPhoto),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomFilledButton(
                text: _page < 3 ? 'Siguiente' : 'Enviar emergencia',
                isLoading: _isLoading && _page == 3,
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ), // Scaffold
    ); // PopScope
  }
}

class _StepDescription extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;

  const _StepDescription({required this.titleCtrl, required this.descCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          CustomInputField(
            label: 'Título del problema',
            controller: titleCtrl,
            prefixIcon: Icons.title_rounded,
          ),
          const SizedBox(height: 16),
          CustomInputField(
            label: 'Descripción detallada',
            controller: descCtrl,
            maxLines: 4,
            prefixIcon: Icons.description_outlined,
          ),
        ],
      ),
    );
  }
}

class _StepVehicle extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final VehicleModel? selected;
  final ValueChanged<VehicleModel> onSelect;

  const _StepVehicle({
    required this.vehicles,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return const Center(
        child: Text(
          'No tienes vehículos registrados.\nAgrega uno en "Mis Vehículos".',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: vehicles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final v = vehicles[i];
        final isSelected = selected?.id == v.id;
        return ListTile(
          tileColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.directions_car_rounded),
          title: Text('${v.brand} ${v.model}'),
          subtitle: Text(v.plate),
          trailing: isSelected ? const Icon(Icons.check_circle_rounded) : null,
          onTap: () => onSelect(v),
        );
      },
    );
  }
}

class _StepLocation extends StatelessWidget {
  final Position? position;
  final bool isLoading;
  final VoidCallback onGetLocation;

  const _StepLocation({
    required this.position,
    required this.isLoading,
    required this.onGetLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 64,
            color: position != null
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          if (position != null) ...[
            Text(
              'Ubicación obtenida',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${position!.latitude.toStringAsFixed(6)}\nLng: ${position!.longitude.toStringAsFixed(6)}',
              textAlign: TextAlign.center,
            ),
          ] else
            const Text('Presiona el botón para obtener tu ubicación actual.'),
          const SizedBox(height: 24),
          CustomFilledButton(
            text: position != null
                ? 'Actualizar ubicación'
                : 'Obtener ubicación GPS',
            isLoading: isLoading,
            onPressed: onGetLocation,
            icon: Icons.my_location_rounded,
            buttonColor: position != null ? Colors.green : null,
          ),
        ],
      ),
    );
  }
}

class _StepEvidences extends StatelessWidget {
  final XFile? photo;
  final VoidCallback onPickPhoto;

  const _StepEvidences({required this.photo, required this.onPickPhoto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_rounded,
            size: 64,
            color: photo != null
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            photo != null ? 'Foto tomada' : 'Foto (opcional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            photo != null
                ? photo!.name
                : 'Toma una foto del problema para acelerar el diagnóstico.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          CustomFilledButton(
            text: photo != null ? 'Cambiar foto' : 'Tomar foto',
            onPressed: onPickPhoto,
            icon: Icons.camera_alt_rounded,
            buttonColor: photo != null ? Colors.green : null,
          ),
        ],
      ),
    );
  }
}
