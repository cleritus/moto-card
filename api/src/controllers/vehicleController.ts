import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { vehicleService } from '../services/vehicleService';
import { createError } from '../middleware/errorHandler';
import { getPaginationParams } from '../utils/pagination';

export const vehicleController = {
  /**
   * Get all vehicles for the authenticated user
   * GET /api/vehicles?page=1&limit=20
   */
  getAllVehicles: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    const { page, limit } = getPaginationParams(req.query);
    const result = await vehicleService.getAllVehicles(userId, page, limit);

    res.status(200).json({
      success: true,
      data: { vehicles: result.data },
      pagination: result.pagination,
    });
  }),

  /**
   * Get a single vehicle by ID
   * GET /api/vehicles/:id
   */
  getVehicleById: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!id) {
      throw createError('Vehicle ID is required', 400);
    }

    const vehicle = await vehicleService.getVehicleById(userId, id);

    res.status(200).json({
      success: true,
      data: { vehicle },
    });
  }),

  /**
   * Create a new vehicle
   * POST /api/vehicles
   */
  createVehicle: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { name, make, vehicleModel, year, mileage } = req.body;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    // Validation
    if (!name || !make || !vehicleModel || !year) {
      throw createError('Name, make, model, and year are required', 400);
    }

    const vehicle = await vehicleService.createVehicle(userId, {
      name,
      make,
      vehicleModel,
      year: parseInt(year, 10),
      mileage: mileage ? parseInt(mileage, 10) : undefined,
    });

    res.status(201).json({
      success: true,
      data: { vehicle },
    });
  }),

  /**
   * Update a vehicle
   * PUT /api/vehicles/:id
   */
  updateVehicle: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { id } = req.params;
    const { name, make, vehicleModel, year, mileage } = req.body;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!id) {
      throw createError('Vehicle ID is required', 400);
    }

    // Build update data (only include defined fields)
    const updateData: { name?: string; make?: string; vehicleModel?: string; year?: number; mileage?: number } = {};
    if (name !== undefined) updateData.name = name;
    if (make !== undefined) updateData.make = make;
    if (vehicleModel !== undefined) updateData.vehicleModel = vehicleModel;
    if (year !== undefined) updateData.year = parseInt(year, 10);
    if (mileage !== undefined) updateData.mileage = parseInt(mileage, 10);

    const vehicle = await vehicleService.updateVehicle(userId, id, updateData);

    res.status(200).json({
      success: true,
      data: { vehicle },
    });
  }),

  /**
   * Delete a vehicle
   * DELETE /api/vehicles/:id
   */
  deleteVehicle: asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { id } = req.params;

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    if (!id) {
      throw createError('Vehicle ID is required', 400);
    }

    await vehicleService.deleteVehicle(userId, id);

    res.status(200).json({
      success: true,
      message: 'Vehicle deleted successfully',
    });
  }),
};