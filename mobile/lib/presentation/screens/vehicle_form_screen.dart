import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/section_header.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const VehicleFormScreen({super.key, this.id});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _makeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loadVehicle();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _vehicleModelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicle() async {
    final notifier = ref.read(vehicleDetailNotifierProvider(widget.id!));
    await notifier.loadVehicle(widget.id!);
    final state = ref.read(vehicleDetailProvider(widget.id!));
    if (state.vehicle != null) {
      final vehicle = state.vehicle!;
      _nameController.text = vehicle.name;
      _makeController.text = vehicle.make;
      _vehicleModelController.text = vehicle.vehicleModel;
      _yearController.text = vehicle.year.toString();
      if (vehicle.mileage != null) {
        _mileageController.text = vehicle.mileage.toString();
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final vehicle = Vehicle(
        id: widget.id ?? '',
        userId: '', // Ustawione przez backend
        name: _nameController.text.trim(),
        make: _makeController.text.trim(),
        vehicleModel: _vehicleModelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        mileage: _mileageController.text.trim().isNotEmpty
            ? int.parse(_mileageController.text.trim())
            : null,
        createdAt: widget.id != null
            ? ref.read(vehicleDetailProvider(widget.id!)).vehicle?.createdAt ??
                DateTime.now()
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() => _isLoading = true);

      Future(() async {
        try {
          final providerKey = widget.id ?? 'new';
          final notifier = ref.read(vehicleDetailNotifierProvider(providerKey));

          if (widget.id != null) {
            await notifier.updateVehicle(vehicle);
            final state = ref.read(vehicleDetailProvider(widget.id!));
            if (state.status == VehicleDetailStatus.error) {
              setState(() {
                _errorMessage = state.errorMessage;
                _isLoading = false;
              });
              return;
            }
          } else {
            await notifier.createVehicle(vehicle);
            final state = ref.read(vehicleDetailProvider('new'));
            if (state.status == VehicleDetailStatus.error) {
              setState(() {
                _errorMessage = state.errorMessage;
                _isLoading = false;
              });
              return;
            }
          }
          if (mounted) {
            ref.read(vehicleListProvider.notifier).refresh();
            context.pop();
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only watch provider for edit mode, not create mode
    if (widget.id != null) {
      ref.listen<VehicleDetailState>(vehicleDetailProvider(widget.id!), (previous, next) {
        // Handle error from loading or updating
        if (next.status == VehicleDetailStatus.error && next.errorMessage != null) {
          setState(() {
            _errorMessage = next.errorMessage;
            _isLoading = false;
          });
        } else if (next.status == VehicleDetailStatus.loaded && _isLoading) {
          if (mounted) {
            setState(() => _errorMessage = null);
            ref.read(vehicleListProvider.notifier).refresh();
            context.pop();
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id != null ? 'EDYTUJ POJAZD' : 'NOWY POJAZD'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Dane podstawowe', padded: false),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa',
                    prefixIcon: Icon(Icons.text_fields),
                    hintText: 'np. Mój motocykl',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj nazwę pojazdu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _makeController,
                  decoration: const InputDecoration(
                    labelText: 'Marka',
                    prefixIcon: Icon(Icons.directions_car),
                    hintText: 'np. Honda',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj markę';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    prefixIcon: Icon(Icons.motorcycle),
                    hintText: 'np. CBR600RR',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'Rok produkcji',
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: 'np. 2020',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj rok produkcji';
                    }
                    final year = int.tryParse(value.trim());
                    if (year == null) {
                      return 'Podaj prawidłowy rok';
                    }
                    if (year < 1900 || year > DateTime.now().year + 1) {
                      return 'Rok musi być między 1900 a ${DateTime.now().year + 1}';
                    }
                    return null;
                  },
                ),
                const SectionHeader('Szczegóły', padded: false),
                TextFormField(
                  controller: _mileageController,
                  decoration: const InputDecoration(
                    labelText: 'Przebieg (km)',
                    prefixIcon: Icon(Icons.speed),
                    hintText: 'np. 15000',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final mileage = int.tryParse(value.trim());
                      if (mileage == null || mileage < 0) {
                        return 'Podaj prawidłowy przebieg';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.darkAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.darkOnPrimary,
                          ),
                        )
                      : Text(widget.id != null ? 'ZAPISZ ZMIANY' : 'DODAJ POJAZD'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  child: const Text('ANULUJ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}