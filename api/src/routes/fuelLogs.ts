import { Router } from 'express';
import { fuelLogController } from '../controllers/fuelLogController';
import { authenticate } from '../middleware/auth';
import { validateFuelLogCreate, validateFuelLogUpdate } from '../utils/validation';

const router = Router();

// All fuel log routes require authentication
router.use(authenticate);

// GET /api/fuel-logs/:vehicleId - Get all fuel logs for a vehicle
router.get('/:vehicleId', fuelLogController.getAllFuelLogs);

// GET /api/fuel-logs/:vehicleId/:id - Get single fuel log
router.get('/:vehicleId/:id', fuelLogController.getFuelLogById);

// POST /api/fuel-logs/:vehicleId - Create new fuel log
router.post('/:vehicleId', ...validateFuelLogCreate, fuelLogController.createFuelLog);

// PUT /api/fuel-logs/:vehicleId/:id - Update fuel log
router.put('/:vehicleId/:id', ...validateFuelLogUpdate, fuelLogController.updateFuelLog);

// DELETE /api/fuel-logs/:vehicleId/:id - Delete fuel log
router.delete('/:vehicleId/:id', fuelLogController.deleteFuelLog);

export default router;
