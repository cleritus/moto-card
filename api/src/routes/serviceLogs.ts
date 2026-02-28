import { Router } from 'express';
import { serviceLogController } from '../controllers/serviceLogController';
import { authenticate } from '../middleware/auth';
import { validateServiceLogCreate, validateServiceLogUpdate } from '../utils/validation';

const router = Router();

// All service log routes require authentication
router.use(authenticate);

// GET /api/service-logs/:vehicleId - Get all service logs for a vehicle (with pagination)
router.get('/:vehicleId', serviceLogController.getAllServiceLogs);

// GET /api/service-logs/:vehicleId/:id - Get single service log
router.get('/:vehicleId/:id', serviceLogController.getServiceLogById);

// POST /api/service-logs/:vehicleId - Create new service log
router.post('/:vehicleId', ...validateServiceLogCreate, serviceLogController.createServiceLog);

// PUT /api/service-logs/:vehicleId/:id - Update service log
router.put('/:vehicleId/:id', ...validateServiceLogUpdate, serviceLogController.updateServiceLog);

// DELETE /api/service-logs/:vehicleId/:id - Delete service log
router.delete('/:vehicleId/:id', serviceLogController.deleteServiceLog);

export default router;