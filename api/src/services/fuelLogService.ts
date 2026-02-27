import FuelLog, { IFuelLog } from '../models/FuelLog';
import Vehicle from '../models/Vehicle';
import { createError } from '../middleware/errorHandler';

export interface FuelLogCreateData {
  date?: Date;
  mileage: number;
  fuelAmount: number;
  totalCost: number;
  notes?: string;
}

export interface FuelLogUpdateData {
  date?: Date;
  mileage?: number;
  fuelAmount?: number;
  totalCost?: number;
  notes?: string;
}

export class FuelLogService {
  /**
   * Verify that the user owns the vehicle
   */
  private async verifyVehicleOwnership(userId: string, vehicleId: string): Promise<void> {
    const vehicle = await Vehicle.findByUserAndId(userId, vehicleId);
    if (!vehicle) {
      throw createError('Vehicle not found or access denied', 404);
    }
  }

  /**
   * Get all fuel logs for a vehicle
   */
  async getAllFuelLogs(userId: string, vehicleId: string): Promise<IFuelLog[]> {
    await this.verifyVehicleOwnership(userId, vehicleId);
    return FuelLog.findByVehicle(vehicleId);
  }

  /**
   * Get a single fuel log by ID (with ownership check)
   */
  async getFuelLogById(userId: string, vehicleId: string, fuelLogId: string): Promise<IFuelLog> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const fuelLog = await FuelLog.findByVehicleAndId(vehicleId, fuelLogId);

    if (!fuelLog) {
      throw createError('Fuel log not found', 404);
    }

    return fuelLog;
  }

  /**
   * Create a new fuel log
   */
  async createFuelLog(
    userId: string,
    vehicleId: string,
    data: FuelLogCreateData
  ): Promise<IFuelLog> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const fuelLog = await FuelLog.create({
      vehicleId,
      date: data.date || new Date(),
      mileage: data.mileage,
      fuelAmount: data.fuelAmount,
      totalCost: data.totalCost,
      notes: data.notes,
    });

    return fuelLog;
  }

  /**
   * Update a fuel log (with ownership check)
   */
  async updateFuelLog(
    userId: string,
    vehicleId: string,
    fuelLogId: string,
    data: FuelLogUpdateData
  ): Promise<IFuelLog> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const fuelLog = await FuelLog.findByVehicleAndId(vehicleId, fuelLogId);

    if (!fuelLog) {
      throw createError('Fuel log not found', 404);
    }

    // Update only provided fields
    if (data.date !== undefined) fuelLog.set('date', data.date);
    if (data.mileage !== undefined) fuelLog.set('mileage', data.mileage);
    if (data.fuelAmount !== undefined) fuelLog.set('fuelAmount', data.fuelAmount);
    if (data.totalCost !== undefined) fuelLog.set('totalCost', data.totalCost);
    if (data.notes !== undefined) fuelLog.set('notes', data.notes);

    await fuelLog.save();
    return fuelLog;
  }

  /**
   * Delete a fuel log (with ownership check)
   */
  async deleteFuelLog(userId: string, vehicleId: string, fuelLogId: string): Promise<void> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const fuelLog = await FuelLog.findByVehicleAndId(vehicleId, fuelLogId);

    if (!fuelLog) {
      throw createError('Fuel log not found', 404);
    }

    await FuelLog.deleteOne({ _id: fuelLogId, vehicleId });
  }
}

// Export singleton instance
export const fuelLogService = new FuelLogService();
