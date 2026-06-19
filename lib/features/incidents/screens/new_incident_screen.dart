import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:si2_p1_mobile/core/models/local_incident_model.dart';
import 'package:si2_p1_mobile/core/models/vehicle_model.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/core/services/local_incident_repository.dart';
import 'package:si2_p1_mobile/core/services/vehicle_service.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_filled_button.dart';

class NewIncidentScreen extends ConsumerStatefulWidget {
  static const name = 'new-incident';

  const NewIncidentScreen({super.key});

  @override
  ConsumerState<NewIncidentScreen> createState() => _NewIncidentScreenState();
}

class _NewIncidentScreenState extends ConsumerState<NewIncidentScreen> {
  static const _maxImages = 4;
  static const _audioEncoder = AudioEncoder.wav;
  static const _audioExtension = 'wav';
  static const _audioMimeType = 'audio/wav';

  final _descriptionCtrl = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _imagePicker = ImagePicker();
  StreamSubscription<void>? _audioCompleteSub;
  StreamSubscription<PlayerState>? _audioStateSub;
  StreamSubscription<Duration>? _audioDurationSub;
  StreamSubscription<String>? _audioLogSub;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isLoadingVehicles = false;
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  bool _requiresTow = false;
  String _serviceModality = 'A_DOMICILIO';
  List<VehicleModel> _vehicles = [];
  VehicleModel? _selectedVehicle;
  int? _vehiclesLoadedForUserId;
  Position? _position;
  final List<XFile> _images = [];
  String? _audioPath;
  String? _lastRequestedAudioPath;

  @override
  void initState() {
    super.initState();
    _descriptionCtrl.addListener(_refreshSubmitState);
    _audioCompleteSub = _audioPlayer.onPlayerComplete.listen(
      (_) {
        debugPrint('[EmergencyAudio] player complete');
        if (mounted) setState(() => _isPlayingAudio = false);
      },
      onError: (Object error) {
        debugPrint('[EmergencyAudio] player complete stream error=$error');
      },
    );
    _audioStateSub = _audioPlayer.onPlayerStateChanged.listen(
      (state) => debugPrint('[EmergencyAudio] player state=$state'),
      onError: (Object error) {
        debugPrint('[EmergencyAudio] player state stream error=$error');
      },
    );
    _audioDurationSub = _audioPlayer.onDurationChanged.listen(
      (duration) => debugPrint(
        '[EmergencyAudio] player duration=${duration.inMilliseconds}ms',
      ),
      onError: (Object error) {
        debugPrint('[EmergencyAudio] player duration stream error=$error');
      },
    );
    _audioLogSub = _audioPlayer.onLog.listen(
      (message) => debugPrint('[EmergencyAudio] player log=$message'),
      onError: (Object error) {
        debugPrint('[EmergencyAudio] player log stream error=$error');
      },
    );
    _loadVehicles();
  }

  @override
  void dispose() {
    _descriptionCtrl.removeListener(_refreshSubmitState);
    _descriptionCtrl.dispose();
    _audioCompleteSub?.cancel();
    _audioStateSub?.cancel();
    _audioDurationSub?.cancel();
    _audioLogSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  bool get _hasEmergencyInput =>
      _descriptionCtrl.text.trim().isNotEmpty ||
      (_audioPath != null && _audioPath!.isNotEmpty);

  bool get _canSubmit =>
      _hasEmergencyInput &&
      _selectedVehicle != null &&
      _position != null &&
      !_isSubmitting;

  String get _submitHelpText {
    if (_isSubmitting) return 'Enviando emergencia...';

    final missing = <String>[
      if (!_hasEmergencyInput) 'descripcion o nota de voz',
      if (_selectedVehicle == null) 'vehiculo',
      if (_position == null) 'ubicacion',
    ];
    if (missing.isEmpty) {
      return 'Listo para enviar. Puedes usar texto o nota de voz; imagenes son opcionales.';
    }
    return 'Falta: ${missing.join(', ')}.';
  }

  void _refreshSubmitState() {
    if (mounted) setState(() {});
  }

  Future<void> _loadVehicles({int? userId}) async {
    userId ??= ref.read(authProvider).user?.id;
    if (userId == null) return;
    if (_isLoadingVehicles || _vehiclesLoadedForUserId == userId) return;

    try {
      setState(() => _isLoadingVehicles = true);
      final vehicles = await VehicleService().getMyVehicles(userId);
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _selectedVehicle =
            vehicles.any((vehicle) => vehicle.id == _selectedVehicle?.id)
            ? _selectedVehicle
            : null;
        _vehiclesLoadedForUserId = userId;
        _isLoadingVehicles = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingVehicles = false);
      AppToast.error(context, message: 'No se pudieron cargar tus vehiculos');
    }
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        AppToast.error(
          context,
          message: 'Permiso de ubicacion denegado permanentemente',
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        AppToast.warning(context, message: 'Necesitamos tu ubicacion actual');
        return;
      }

      setState(() => _isLoading = true);
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = position;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(context, message: 'Error al obtener ubicacion');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      AppToast.warning(context, message: 'Permiso de microfono requerido');
      return;
    }

    if (_isPlayingAudio) {
      debugPrint('[EmergencyAudio] stop before recording');
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlayingAudio = false);
    }

    final wavSupported = await _audioRecorder.isEncoderSupported(_audioEncoder);
    debugPrint(
      '[EmergencyAudio] encoder=${_audioEncoder.name} supported=$wavSupported',
    );

    final path =
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'emergencia_${const Uuid().v4()}.$_audioExtension';
    _lastRequestedAudioPath = path;
    debugPrint('[EmergencyAudio] record.start requestedPath=$path');

    await _audioRecorder.start(
      const RecordConfig(encoder: _audioEncoder),
      path: path,
    );

    if (!mounted) return;
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    await _logRecordedAudio(path);
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      if (path != null && path.isNotEmpty) _audioPath = path;
    });
  }

  Future<void> _logRecordedAudio(String? returnedPath) async {
    final requestedPath = _lastRequestedAudioPath;
    final supported = await _audioRecorder.isEncoderSupported(_audioEncoder);
    final extension = returnedPath == null
        ? '<null>'
        : returnedPath.split('.').last.toLowerCase();
    final file = returnedPath == null ? null : File(returnedPath);
    final exists = file?.existsSync() ?? false;
    final bytes = exists ? file!.lengthSync() : 0;

    debugPrint('[EmergencyAudio] record.stop returnedPath=$returnedPath');
    debugPrint(
      '[EmergencyAudio] record.requestedPath=$requestedPath '
      'sameAsReturned=${requestedPath == returnedPath}',
    );
    debugPrint(
      '[EmergencyAudio] record.file exists=$exists bytes=$bytes '
      'extension=$extension encoder=${_audioEncoder.name} '
      'supported=$supported',
    );
  }

  Future<void> _toggleAudioPlayback() async {
    final path = _audioPath;
    if (path == null) return;
    if (_isRecording) {
      AppToast.warning(
        context,
        message: 'Deten la grabacion antes de escuchar',
      );
      return;
    }

    if (_isPlayingAudio) {
      debugPrint(
        '[EmergencyAudio] player stop requested state=${_audioPlayer.state}',
      );
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlayingAudio = false);
      return;
    }

    try {
      final file = File(path);
      final exists = file.existsSync();
      final bytes = exists ? file.lengthSync() : 0;
      debugPrint(
        '[EmergencyAudio] play.start path=$path exists=$exists bytes=$bytes '
        'stateBefore=${_audioPlayer.state}',
      );
      await _audioPlayer.play(
        DeviceFileSource(path, mimeType: _audioMimeType),
        volume: 1,
        ctx: AudioContextConfig(route: AudioContextConfigRoute.speaker).build(),
      );
      final duration = await _audioPlayer.getDuration();
      debugPrint(
        '[EmergencyAudio] play.invoked state=${_audioPlayer.state} '
        'durationMs=${duration?.inMilliseconds}',
      );
      if (mounted) setState(() => _isPlayingAudio = true);
    } catch (error) {
      debugPrint('[EmergencyAudio] play.error=$error');
      if (!mounted) return;
      setState(() => _isPlayingAudio = false);
      AppToast.error(context, message: 'No se pudo reproducir la nota de voz');
    }
  }

  void _clearAudio() {
    debugPrint('[EmergencyAudio] clear audio stop state=${_audioPlayer.state}');
    _audioPlayer.stop();
    setState(() {
      _audioPath = null;
      _isPlayingAudio = false;
    });
  }

  Future<void> _pickCameraImage() async {
    if (_images.length >= _maxImages) {
      AppToast.warning(context, message: 'Maximo $_maxImages imagenes');
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;
    setState(() => _images.add(image));
    debugPrint(
      '[EmergencyEvidence] camera image selected count=${_images.length} '
      'file=${_fileName(image.path)}',
    );
  }

  Future<void> _pickGalleryImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) {
      AppToast.warning(context, message: 'Maximo $_maxImages imagenes');
      return;
    }

    final images = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty || !mounted) return;
    setState(() => _images.addAll(images.take(remaining)));
    debugPrint(
      '[EmergencyEvidence] gallery images selected added=${images.take(remaining).length} '
      'count=${_images.length} files=${images.take(remaining).map((image) => _fileName(image.path)).join(', ')}',
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (_isRecording) {
      await _stopRecording();
    }

    final description = _descriptionCtrl.text.trim();
    final hasAudio = _audioPath != null && _audioPath!.isNotEmpty;
    if (description.isEmpty && !hasAudio) {
      AppToast.warning(
        context,
        message: 'Escribe una descripcion o graba una nota de voz',
      );
      return;
    }
    if (_selectedVehicle == null) {
      AppToast.warning(context, message: 'Selecciona tu vehiculo');
      return;
    }
    if (_position == null) {
      AppToast.warning(context, message: 'Confirma tu ubicacion en el mapa');
      return;
    }

    setState(() => _isSubmitting = true);

    final clientUserId = ref.read(authProvider).user?.id;
    if (clientUserId == null) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final uuidCliente = const Uuid().v4();
    final descriptionForRequest = description.isNotEmpty
        ? description
        : 'Emergencia enviada con nota de voz';
    final title = description.isNotEmpty
        ? _buildTitle(description)
        : 'Emergencia por nota de voz';
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((r) => r != ConnectivityResult.none);

    if (!isOnline) {
      final draft = LocalIncidentModel(
        uuid: uuidCliente,
        title: title,
        descriptionText: descriptionForRequest,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        vehicleId: _selectedVehicle!.id,
        syncStatus: 'PENDIENTE_SYNC',
      );
      await LocalIncidentRepository().save(draft);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.info(
        context,
        message:
            'Sin conexion. Emergencia guardada; las evidencias no se adjuntan offline todavia.',
      );
      context.go('/home');
      return;
    }

    try {
      final service = IncidentService();
      final incident = await service.createIncident(
        clientUserId: clientUserId,
        vehicleId: _selectedVehicle!.id,
        title: title,
        descriptionText: descriptionForRequest,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        requiresTow: _requiresTow,
        serviceModality: _serviceModality,
        uuidCliente: uuidCliente,
      );

      try {
        final imagePaths = _images.map((image) => image.path).toList();
        debugPrint(
          '[EmergencyEvidence] sending ai-analysis incident=${incident.id} '
          'audio=${_audioPath != null} images=${imagePaths.length} '
          'files=${imagePaths.map(_fileName).join(', ')}',
        );
        await service.analyzeIncident(
          incident.id,
          imagePaths: imagePaths,
          audioPath: _audioPath,
        );
      } catch (_) {
        if (mounted) {
          AppToast.warning(
            context,
            message: 'Emergencia enviada; analisis IA pendiente',
          );
        }
      }

      if (mounted) context.go('/incidents/${incident.id}/tracking');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.error(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  String _buildTitle(String description) {
    final normalized = description.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 80) return normalized;
    return '${normalized.substring(0, 77)}...';
  }

  String _fileName(String path) => path.split(Platform.pathSeparator).last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final authUserId = authState.user?.id;
    final canSubmit = _canSubmit;

    if (authUserId != null &&
        _vehiclesLoadedForUserId != authUserId &&
        !_isLoadingVehicles) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadVehicles(userId: authUserId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva emergencia'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(
                icon: Icons.notes_rounded,
                title: 'Describe el problema',
                subtitle: 'Escribe lo necesario o deja una nota de voz.',
              ),
              const SizedBox(height: 10),
              _DescriptionBox(
                controller: _descriptionCtrl,
                isRecording: _isRecording,
                isPlayingAudio: _isPlayingAudio,
                hasAudio: _audioPath != null,
                onToggleRecording: _toggleRecording,
                onPlayAudio: _audioPath == null ? null : _toggleAudioPlayback,
                onClearAudio: _audioPath == null ? null : _clearAudio,
              ),
              const SizedBox(height: 22),

              _SectionTitle(
                icon: Icons.directions_car_rounded,
                title: 'Vehiculo',
                subtitle: 'Elige el vehiculo que necesita auxilio.',
              ),
              const SizedBox(height: 10),
              _VehicleSelector(
                vehicles: _vehicles,
                isLoading:
                    _isLoadingVehicles ||
                    (authState.status == AuthStatus.checking &&
                        _vehiclesLoadedForUserId == null),
                selected: _selectedVehicle,
                onChanged: (vehicle) => setState(() {
                  _selectedVehicle = vehicle;
                }),
              ),
              const SizedBox(height: 22),

              _SectionTitle(
                icon: Icons.photo_camera_rounded,
                title: 'Imagenes para diagnostico IA',
                subtitle: 'Agrega fotos claras del incidente si puedes.',
              ),
              const SizedBox(height: 10),
              _EvidencePicker(
                images: _images,
                onCamera: _pickCameraImage,
                onGallery: _pickGalleryImages,
                onRemove: _removeImage,
                fileName: _fileName,
              ),
              const SizedBox(height: 16),

              // ── Modalidad de servicio ────────────────────────────
              _SectionTitle(
                icon: Icons.route_rounded,
                title: 'Tipo de servicio',
                subtitle: 'Elige como quieres recibir la asistencia.',
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Que vengan a mi ubicación'),
                      subtitle: const Text('Un técnico o grúa irá hacia donde estás.'),
                      value: 'A_DOMICILIO',
                      groupValue: _serviceModality,
                      onChanged: (v) { if (v != null) setState(() => _serviceModality = v); },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    RadioListTile<String>(
                      title: const Text('Yo iré al taller'),
                      subtitle: const Text('El problema es leve y puedo conducir hasta el taller.'),
                      value: 'CLIENTE_VE_TALLER',
                      groupValue: _serviceModality,
                      onChanged: (v) { if (v != null) setState(() => _serviceModality = v); },
                    ),
                  ],
                ),
              ),
              if (_serviceModality == 'A_DOMICILIO') ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Requiere remolque / grúa'),
                  subtitle: const Text('El vehículo no puede moverse por sí mismo.'),
                  value: _requiresTow,
                  onChanged: (v) => setState(() => _requiresTow = v ?? false),
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
              const SizedBox(height: 22),

              _SectionTitle(
                icon: Icons.location_on_rounded,
                title: 'Ubicacion',
                subtitle: _serviceModality == 'CLIENTE_VE_TALLER'
                    ? 'Tu ubicación actual para buscar talleres cercanos.'
                    : 'Confirma donde debe llegar el taller.',
              ),
              const SizedBox(height: 10),
              _LocationPicker(
                position: _position,
                isLoading: _isLoading,
                onGetLocation: _getLocation,
              ),
              const SizedBox(height: 28),
              CustomFilledButton(
                text: 'Enviar emergencia',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                isEnabled: canSubmit,
                onPressed: canSubmit ? _submit : null,
              ),
              const SizedBox(height: 6),
              Text(
                _submitHelpText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DescriptionBox extends StatelessWidget {
  final TextEditingController controller;
  final bool isRecording;
  final bool isPlayingAudio;
  final bool hasAudio;
  final VoidCallback onToggleRecording;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onClearAudio;

  const _DescriptionBox({
    required this.controller,
    required this.isRecording,
    required this.isPlayingAudio,
    required this.hasAudio,
    required this.onToggleRecording,
    required this.onPlayAudio,
    required this.onClearAudio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audioColor = isRecording
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 7,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Ej.: Se pincho una llanta y estoy detenido en la via.',
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(14, 14, 14, 8),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: isRecording ? 'Detener audio' : 'Grabar audio',
                  onPressed: onToggleRecording,
                  icon: Icon(
                    isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: audioColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    isRecording
                        ? 'Grabando nota de voz...'
                        : isPlayingAudio
                        ? 'Reproduciendo nota de voz...'
                        : hasAudio
                        ? 'Nota de voz lista para analisis IA'
                        : 'Puedes agregar una nota de voz',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasAudio || isRecording
                          ? audioColor
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (hasAudio && !isRecording)
                  IconButton(
                    tooltip: isPlayingAudio
                        ? 'Detener reproduccion'
                        : 'Escuchar audio',
                    onPressed: onPlayAudio,
                    icon: Icon(
                      isPlayingAudio
                          ? Icons.stop_circle_rounded
                          : Icons.play_circle_rounded,
                    ),
                  ),
                if (hasAudio && !isRecording)
                  IconButton(
                    tooltip: 'Quitar audio',
                    onPressed: onClearAudio,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleSelector extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final bool isLoading;
  final VehicleModel? selected;
  final ValueChanged<VehicleModel?> onChanged;

  const _VehicleSelector({
    required this.vehicles,
    required this.isLoading,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(child: Text('Cargando tus vehiculos...')),
          ],
        ),
      );
    }

    if (vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded),
            SizedBox(width: 10),
            Expanded(child: Text('No tienes vehiculos registrados.')),
          ],
        ),
      );
    }

    return DropdownButtonFormField<VehicleModel>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.directions_car_rounded),
        border: OutlineInputBorder(),
        labelText: 'Selecciona tu vehiculo',
      ),
      items: vehicles.map((vehicle) {
        return DropdownMenuItem(
          value: vehicle,
          child: Text(
            '${vehicle.brand} ${vehicle.model} - ${vehicle.plate}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _EvidencePicker extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<int> onRemove;
  final String Function(String path) fileName;

  const _EvidencePicker({
    required this.images,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Camara'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Galeria'),
              ),
            ),
          ],
        ),
        if (images.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Opcional, pero ayuda a clasificar el incidente.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final image = images[index];
                return SizedBox(
                  width: 92,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(image.path),
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filled(
                          constraints: const BoxConstraints.tightFor(
                            width: 30,
                            height: 30,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Quitar ${fileName(image.path)}',
                          onPressed: () => onRemove(index),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationPicker extends StatelessWidget {
  final Position? position;
  final bool isLoading;
  final VoidCallback onGetLocation;

  const _LocationPicker({
    required this.position,
    required this.isLoading,
    required this.onGetLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = position == null
        ? null
        : LatLng(position!.latitude, position!.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 190,
            child: current == null
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 42,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tu ubicacion aparecera aqui',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: current,
                      initialZoom: 16,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'si2_p1_mobile',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: current,
                            width: 46,
                            height: 46,
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 46,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onGetLocation,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_rounded),
          label: Text(
            current == null
                ? 'Usar mi ubicacion actual'
                : 'Actualizar ubicacion',
          ),
        ),
        if (current != null) ...[
          const SizedBox(height: 6),
          Text(
            'Lat ${current.latitude.toStringAsFixed(6)} - Lng ${current.longitude.toStringAsFixed(6)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
