import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { fuelLogService } from '../services/fuelLogService';
import { createError } from '../middleware/errorHandler';

export const fuelLogController = {
  /**
   * Get all fuel logs for a vehicle
   * GET /api/fuel-logs/:vehicleId
   */
  getAllFuelLogs: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    const fuelLogs = await fuelLogService.getAllFuelLogs(userId, vehicleId);

    res.status(200).json({
      success: true,
      count: fuelLogs.length,
      data: { fuelLogs },
    });
  }),

  /**
   * Get a single fuel log by ID
   * GET /api/fuel-logs/:vehicleId/:id
   */
  getFuelLogById: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Fuel log ID is required', 400);
    }

    const fuelLog = await fuelLogService.getFuelLogById(userId, vehicleId, id);

    res.status(200).json({
      success: true,
      data: { fuelLog },
    });
  }),

  /**
   * Create a new fuel log
   * POST /api/fuel-logs/:vehicleId
   */
  createFuelLog: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId } = req.params;
    const { date, mileage, fuelAmount, totalCost, notes } = req.body;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    // Validation
    if (mileage === undefined || fuelAmount === undefined || totalCost === undefined) {
      throw createError('Mileage, fuel amount, and total cost are required', 400);
    }

    const fuelLog = await fuelLogService.createFuelLog(userId, vehicleId, {
      date: date ? new Date(date) : undefined,
      mileage: parseInt(mileage, 10),
      fuelAmount: parseFloat(fuelAmount),
      totalCost: parseFloat(totalCost),
      notes,
    });

    res.status(201).json({
      success: true,
      data: { fuelLog },
    });
  }),

  /**
   * Update a fuel log
   * PUT /api/fuel-logs/:vehicleId/:id
   */
  updateFuelLog: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;
    const { date, mileage, fuelAmount, totalCost, notes } = req.body;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Fuel log ID is required', 400);
    }

    // Build update data (only include defined fields)
    const updateData: {
      date?: Date;
      mileage?: number;
      fuelAmount?: number;
      totalCost?: number;
      notes?: string;
    } = {};

    if (date !== undefined) updateData.date = new Date(date);
    if (mileage !== undefined) updateData.mileage = parseInt(mileage, 10);
    if (fuelAmount !== undefined) updateData.fuelAmount = parseFloat(fuelAmount);
    if (totalCost !== undefined) updateData.totalCost = parseFloat(totalCost);
    if (notes !== undefined) updateData.notes = notes;

    const fuelLog = await fuelLogService.updateFuelLog(userId, vehicleId, id, updateData);

    res.status(200).json({
      success: true,
      data: { fuelLog },
    });
  }),

  /**
   * Delete a fuel log
   * DELETE /api/fuel-logs/:vehicleId/:id
   */
  deleteFuelLog: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Fuel log ID is required', 400);
    }

    await fuelLogService.deleteFuelLog(userId, vehicleId, id);

    res.status(200).json({
      success: true,
      message: 'Fuel log deleted successfully',
    });
  }),
};
