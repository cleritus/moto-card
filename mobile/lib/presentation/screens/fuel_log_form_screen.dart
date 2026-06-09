import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/fuel_log.dart';
import '../providers/fuel_log_provider.dart';

class FuelLogFormScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String? id;

  const FuelLogFormScreen({super.key, required this.vehicleId, this.id});

  @override
  ConsumerState<FuelLogFormScreen> createState() => _FuelLogFormScreenState();
}

class _FuelLogFormScreenState extends ConsumerState<FuelLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _mileageController = TextEditingController();
  final _fuelAmountController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDate);
    if (widget.id != null) {
      _loadFuelLog();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _mileageController.dispose();
    _fuelAmountController.dispose();
    _totalCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFuelLog() async {
    final state = ref.read(fuelLogDetailProvider((widget.vehicleId, widget.id!)));
    if (state.fuelLog != null) {
      final fuelLog = state.fuelLog!;
      _selectedDate = fuelLog.date;
      _dateController.text = DateFormat('dd.MM.yyyy').format(fuelLog.date);
      _mileageController.text = fuelLog.mileage.toString();
      _fuelAmountController.text = fuelLog.fuelAmount.toString();
      _totalCostController.text = fuelLog.totalCost.toString();
      if (fuelLog.notes != null) {
        _notesController.text = fuelLog.notes!;
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final fuelLog = FuelLog(
        id: widget.id ?? '',
        vehicleId: widget.vehicleId,
        date: _selectedDate,
        mileage: int.parse(_mileageController.text.trim()),
        fuelAmount: double.parse(_fuelAmountController.text.trim()),
        totalCost: double.parse(_totalCostController.text.trim()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.id != null
            ? ref
                    .read(fuelLogDetailProvider((widget.vehicleId, widget.id!)))
                    .fuelLog
                    ?.createdAt ??
                DateTime.now()
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() => _isLoading = true);

      Future(() async {
        try {
          if (widget.id != null) {
            await ref
                .read(fuelLogDetailNotifierProvider((widget.vehicleId, widget.id!)))
                .updateFuelLog(fuelLog);
            final state = ref.read(fuelLogDetailProvider((widget.vehicleId, widget.id!)));
            if (state.status == FuelLogDetailStatus.error) {
              setState(() {
                _errorMessage = state.errorMessage;
                _isLoading = false;
              });
              return;
            }
          } else {
            await ref
                .read(fuelLogDetailNotifierProvider((widget.vehicleId, 'new')))
                .createFuelLog(fuelLog);
            final state = ref.read(fuelLogDetailProvider((widget.vehicleId, 'new')));
            if (state.status == FuelLogDetailStatus.error) {
              setState(() {
                _errorMessage = state.errorMessage;
                _isLoading = false;
              });
              return;
            }
          }
          if (mounted) {
            ref.read(fuelLogListProvider(widget.vehicleId).notifier).refresh();
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
    final providerKey = widget.id ?? 'new';
    ref.listen<FuelLogDetailState>(fuelLogDetailProvider((widget.vehicleId, providerKey)), (previous, next) {
      if (next.status == FuelLogDetailStatus.error && next.errorMessage != null) {
        setState(() {
          _errorMessage = next.errorMessage;
          _isLoading = false;
        });
      } else if (next.status == FuelLogDetailStatus.loaded && _isLoading) {
        if (mounted) {
          setState(() => _errorMessage = null);
          ref.read(fuelLogListProvider(widget.vehicleId).notifier).refresh();
          context.pop();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id != null ? 'Edytuj tankowanie' : 'Nowe tankowanie'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: 'dd.mm.rrrr',
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Wybierz datę';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj przebieg';
                    }
                    final mileage = int.tryParse(value.trim());
                    if (mileage == null || mileage < 0) {
                      return 'Podaj prawidłowy przebieg';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fuelAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Ilość paliwa (L)',
                    prefixIcon: Icon(Icons.local_gas_station),
                    hintText: 'np. 15.5',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj ilość paliwa';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Podaj prawidłową ilość paliwa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalCostController,
                  decoration: const InputDecoration(
                    labelText: 'Koszt (zł)',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: 'np. 120.50',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj koszt';
                    }
                    final cost = double.tryParse(value.trim());
                    if (cost == null || cost < 0) {
                      return 'Podaj prawidłowy koszt';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notatki (opcjonalne)',
                    prefixIcon: Icon(Icons.note),
                    hintText: 'np. Tankowanie na stacji Shell',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.id != null ? 'Zapisz zmiany' : 'Dodaj tankowanie'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  child: const Text('Anuluj'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}