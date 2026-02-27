import { Router } from 'express';
import { vehicleController } from '../controllers/vehicleController';
import { authenticate } from '../middleware/auth';
import { validateVehicleCreate, validateVehicleUpdate } from '../utils/validation';

const router = Router();

// All vehicle routes require authentication
router.use(authenticate);

// GET /api/vehicles - Get all vehicles for user
router.get('/', vehicleController.getAllVehicles);

// GET /api/vehicles/:id - Get single vehicle
router.get('/:id', vehicleController.getVehicleById);

// POST /api/vehicles - Create new vehicle
router.post('/', ...validateVehicleCreate, vehicleController.createVehicle);

// PUT /api/vehicles/:id - Update vehicle
router.put('/:id', ...validateVehicleUpdate, vehicleController.updateVehicle);

// DELETE /api/vehicles/:id - Delete vehicle
router.delete('/:id', vehicleController.deleteVehicle);

export default router;
