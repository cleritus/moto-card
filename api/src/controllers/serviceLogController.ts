import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { serviceLogService } from '../services/serviceLogService';
import { createError } from '../middleware/errorHandler';
import { getPaginationParams } from '../utils/pagination';

export const serviceLogController = {
  /**
   * Get all service logs for a vehicle
   * GET /api/service-logs/:vehicleId?page=1&limit=20
   */
  getAllServiceLogs: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    const { page, limit } = getPaginationParams(req.query);
    const result = await serviceLogService.getAllServiceLogs(userId, vehicleId, page, limit);

    res.status(200).json({
      success: true,
      data: { serviceLogs: result.data },
      pagination: result.pagination,
    });
  }),

  /**
   * Get a single service log by ID
   * GET /api/service-logs/:vehicleId/:id
   */
  getServiceLogById: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Service log ID is required', 400);
    }

    const serviceLog = await serviceLogService.getServiceLogById(userId, vehicleId, id);

    res.status(200).json({
      success: true,
      data: { serviceLog },
    });
  }),

  /**
   * Create a new service log
   * POST /api/service-logs/:vehicleId
   */
  createServiceLog: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId } = req.params;
    const { date, mileage, serviceType, description, mechanic, totalCost, notes } = req.body;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    // Validation
    if (mileage === undefined || serviceType === undefined || totalCost === undefined) {
      throw createError('Mileage, service type, and total cost are required', 400);
    }

    const serviceLog = await serviceLogService.createServiceLog(userId, vehicleId, {
      date: date ? new Date(date) : undefined,
      mileage: parseInt(mileage, 10),
      serviceType,
      description,
      mechanic,
      totalCost: parseFloat(totalCost),
      notes,
    });

    res.status(201).json({
      success: true,
      data: { serviceLog },
    });
  }),

  /**
   * Update a service log
   * PUT /api/service-logs/:vehicleId/:id
   */
  updateServiceLog: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;
    const { date, mileage, serviceType, description, mechanic, totalCost, notes } = req.body;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Service log ID is required', 400);
    }

    // Build update data (only include defined fields)
    const updateData: {
      date?: Date;
      mileage?: number;
      serviceType?: string;
      description?: string;
      mechanic?: string;
      totalCost?: number;
      notes?: string;
    } = {};

    if (date !== undefined) updateData.date = new Date(date);
    if (mileage !== undefined) updateData.mileage = parseInt(mileage, 10);
    if (serviceType !== undefined) updateData.serviceType = serviceType;
    if (description !== undefined) updateData.description = description;
    if (mechanic !== undefined) updateData.mechanic = mechanic;
    if (totalCost !== undefined) updateData.totalCost = parseFloat(totalCost);
    if (notes !== undefined) updateData.notes = notes;

    const serviceLog = await serviceLogService.updateServiceLog(userId, vehicleId, id, updateData);

    res.status(200).json({
      success: true,
      data: { serviceLog },
    });
  }),

  /**
   * Delete a service log
   * DELETE /api/service-logs/:vehicleId/:id
   */
  deleteServiceLog: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { vehicleId, id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!vehicleId) {
      throw createError('Vehicle ID is required', 400);
    }

    if (!id) {
      throw createError('Service log ID is required', 400);
    }

    await serviceLogService.deleteServiceLog(userId, vehicleId, id);

    res.status(200).json({
      success: true,
      message: 'Service log deleted successfully',
    });
  }),
};