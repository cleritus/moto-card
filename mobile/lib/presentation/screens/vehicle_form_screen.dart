import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_app_bar.dart';
import '../widgets/garage_button.dart';
import '../widgets/labeled_field.dart';

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
  final _engineCapacityController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vinController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedPurchaseDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      // Deferred: loadVehicle() mutates provider state synchronously before
      // its first await, which Riverpod forbids during a widget's build.
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadVehicle());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _vehicleModelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _engineCapacityController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _purchaseDateController.dispose();
    _notesController.dispose();
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
      if (vehicle.engineCapacity != null) {
        _engineCapacityController.text = vehicle.engineCapacity.toString();
      }
      _licensePlateController.text = vehicle.licensePlate;
      if (vehicle.vin != null) {
        _vinController.text = vehicle.vin!;
      }
      if (vehicle.purchaseDate != null) {
        _selectedPurchaseDate = vehicle.purchaseDate;
        _purchaseDateController.text =
            DateFormat('dd.MM.yyyy').format(vehicle.purchaseDate!);
      }
      if (vehicle.notes != null) {
        _notesController.text = vehicle.notes!;
      }
    }
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPurchaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedPurchaseDate = picked;
        _purchaseDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
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
        engineCapacity: _engineCapacityController.text.trim().isNotEmpty
            ? int.parse(_engineCapacityController.text.trim())
            : null,
        licensePlate: _licensePlateController.text.trim(),
        vin: _vinController.text.trim().isEmpty
            ? null
            : _vinController.text.trim(),
        purchaseDate: _selectedPurchaseDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
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

    final isEdit = widget.id != null;

    return Scaffold(
      appBar: GarageAppBar(
        title: isEdit ? 'EDYTUJ POJAZD' : 'NOWY POJAZD',
        subtitle: 'FORM 01-A',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppGeo.screenMargin,
            0,
            AppGeo.screenMargin,
            32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FormSection(title: 'DANE PODSTAWOWE', code: 'SEKCJA 1'),
                LabeledField(
                  label: 'NAZWA',
                  child: TextFormField(
                    controller: _nameController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'np. Street Bob'),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj nazwę pojazdu';
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'MARKA',
                  child: TextFormField(
                    controller: _makeController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'np. Honda'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj markę';
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'MODEL',
                  child: TextFormField(
                    controller: _vehicleModelController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'np. CBR600RR'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj model';
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'ROK PRODUKCJI',
                  child: TextFormField(
                    controller: _yearController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'np. 2020'),
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
                ),
                LabeledField(
                  label: 'NR REJESTRACYJNY',
                  child: TextFormField(
                    controller: _licensePlateController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'np. BI619X'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj numer rejestracyjny';
                      }
                      return null;
                    },
                  ),
                ),
                const FormSection(title: 'SZCZEGÓŁY', code: 'SEKCJA 2'),
                LabeledField(
                  label: 'PRZEBIEG / KM',
                  child: TextFormField(
                    controller: _mileageController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'np. 15000'),
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
                ),
                LabeledField(
                  label: 'POJEMNOŚĆ SILNIKA / CM³',
                  hint: 'opcjonalne',
                  child: TextFormField(
                    controller: _engineCapacityController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'np. 1584'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final capacity = int.tryParse(value.trim());
                        if (capacity == null || capacity <= 0) {
                          return 'Podaj prawidłową pojemność';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'VIN',
                  hint: 'opcjonalne',
                  child: TextFormField(
                    controller: _vinController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'np. 1HD1GM4169K328789',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                LabeledField(
                  label: 'DATA ZAKUPU',
                  hint: 'opcjonalne',
                  child: TextFormField(
                    controller: _purchaseDateController,
                    style: AppText.data(size: 14.5),
                    decoration: const InputDecoration(hintText: 'dd.mm.rrrr'),
                    readOnly: true,
                    onTap: _selectPurchaseDate,
                  ),
                ),
                LabeledField(
                  label: 'NOTATKI',
                  hint: 'opcjonalne',
                  child: TextFormField(
                    controller: _notesController,
                    style: AppText.body(size: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'np. znane modyfikacje',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 28),
                if (_errorMessage != null) ...[
                  FaultStrip(message: _errorMessage!),
                  const SizedBox(height: 20),
                ],
                GarageButton(
                  label: isEdit ? 'ZAPISZ ZMIANY' : '+ DO GARAŻU',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
                const SizedBox(height: 14),
                GarageButton.ghost(
                  label: 'ANULUJ',
                  onPressed: _isLoading ? null : () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}