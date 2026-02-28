import { Router } from 'express';
import { reminderController } from '../controllers/reminderController';
import { authenticate } from '../middleware/auth';
import { validateReminderCreate, validateReminderUpdate } from '../utils/validation';

const router = Router();

// All reminder routes require authentication
router.use(authenticate);

// GET /api/reminders/:vehicleId - Get all reminders for a vehicle (with pagination and filter)
router.get('/:vehicleId', reminderController.getAllReminders);

// GET /api/reminders/:vehicleId/:id - Get single reminder
router.get('/:vehicleId/:id', reminderController.getReminderById);

// POST /api/reminders/:vehicleId - Create new reminder
router.post('/:vehicleId', ...validateReminderCreate, reminderController.createReminder);

// PUT /api/reminders/:vehicleId/:id - Update reminder
router.put('/:vehicleId/:id', ...validateReminderUpdate, reminderController.updateReminder);

// DELETE /api/reminders/:vehicleId/:id - Delete reminder
router.delete('/:vehicleId/:id', reminderController.deleteReminder);

// POST /api/reminders/:vehicleId/:id/complete - Mark reminder as completed
router.post('/:vehicleId/:id/complete', reminderController.markAsCompleted);

// POST /api/reminders/:vehicleId/:id/incomplete - Mark reminder as incomplete (undo)
router.post('/:vehicleId/:id/incomplete', reminderController.markAsIncomplete);

export default router;