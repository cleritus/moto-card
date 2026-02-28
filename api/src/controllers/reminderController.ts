import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { reminderService } from '../services/reminderService';
import { createError } from '../middleware/errorHandler';
import { getPaginationParams } from '../utils/pagination';
import { ReminderFilter } from '../models/Reminder';

export const reminderController = {
  /**
   * Get all reminders for a vehicle
   * GET /api/reminders/:vehicleId?page=1&limit=20&filter=active|completed|all
   */
  getAllReminders: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    const { page, limit } = getPaginationParams(req.query);
    const filterParam = req.query.filter as string;
    const filter = Object.values(ReminderFilter).includes(filterParam as ReminderFilter)
      ? (filterParam as ReminderFilter)
      : ReminderFilter.ALL;

    const result = await reminderService.getAllReminders(userId, vehicleId, page, limit, filter);

    res.status(200).json({
      success: true,
      data: { reminders: result.data },
      pagination: result.pagination,
    });
  }),

  /**
   * Get a single reminder by ID
   * GET /api/reminders/:vehicleId/:id
   */
  getReminderById: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Reminder ID is required', 400);
    }

    const reminder = await reminderService.getReminderById(userId, vehicleId, id);

    res.status(200).json({
      success: true,
      data: { reminder },
    });
  }),

  /**
   * Create a new reminder
   * POST /api/reminders/:vehicleId
   */
  createReminder: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId } = req.params;
    const { title, type, dueDate, dueMileage, notes } = req.body;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    // Validation
    if (!title || !type) {
      throw createError('Title and type are required', 400);
    }

    const reminder = await reminderService.createReminder(userId, vehicleId, {
      title,
      type,
      dueDate: dueDate ? new Date(dueDate) : undefined,
      dueMileage: dueMileage !== undefined ? parseInt(dueMileage, 10) : undefined,
      notes,
    });

    res.status(201).json({
      success: true,
      data: { reminder },
    });
  }),

  /**
   * Update a reminder
   * PUT /api/reminders/:vehicleId/:id
   */
  updateReminder: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;
    const { title, type, dueDate, dueMileage, isCompleted, notes } = req.body;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Reminder ID is required', 400);
    }

    // Build update data (only include defined fields)
    const updateData: {
      title?: string;
      type?: 'date' | 'mileage';
      dueDate?: Date;
      dueMileage?: number;
      isCompleted?: boolean;
      notes?: string;
    } = {};

    if (title !== undefined) updateData.title = title;
    if (type !== undefined) updateData.type = type;
    if (dueDate !== undefined) updateData.dueDate = new Date(dueDate);
    if (dueMileage !== undefined) updateData.dueMileage = parseInt(dueMileage, 10);
    if (isCompleted !== undefined) updateData.isCompleted = isCompleted;
    if (notes !== undefined) updateData.notes = notes;

    const reminder = await reminderService.updateReminder(userId, vehicleId, id, updateData);

    res.status(200).json({
      success: true,
      data: { reminder },
    });
  }),

  /**
   * Delete a reminder
   * DELETE /api/reminders/:vehicleId/:id
   */
  deleteReminder: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Reminder ID is required', 400);
    }

    await reminderService.deleteReminder(userId, vehicleId, id);

    res.status(200).json({
      success: true,
      message: 'Reminder deleted successfully',
    });
  }),

  /**
   * Mark a reminder as completed
   * POST /api/reminders/:vehicleId/:id/complete
   */
  markAsCompleted: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Reminder ID is required', 400);
    }

    const reminder = await reminderService.markAsCompleted(userId, vehicleId, id);

    res.status(200).json({
      success: true,
      data: { reminder },
      message: 'Reminder marked as completed',
    });
  }),

  /**
   * Mark a reminder as not completed (undo)
   * POST /api/reminders/:vehicleId/:id/incomplete
   */
  markAsIncomplete: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Reminder ID is required', 400);
    }

    const reminder = await reminderService.markAsIncomplete(userId, vehicleId, id);

    res.status(200).json({
      success: true,
      data: { reminder },
      message: 'Reminder marked as incomplete',
    });
  }),
};