import Vehicle, { IVehicle } from '../models/Vehicle';
import { createError } from '../middleware/errorHandler';
import { buildPaginationMeta, PaginationMeta } from '../utils/pagination';

export interface VehicleCreateData {
  name: string;
  make: string;
  vehicleModel: string;
  year: number;
  mileage?: number;
}

export interface VehicleUpdateData {
  name?: string;
  make?: string;
  vehicleModel?: string;
  year?: number;
  mileage?: number;
}

export interface VehicleListResult {
  data: IVehicle[];
  pagination: PaginationMeta;
}

export class VehicleService {
  /**
   * Get all vehicles for a user with pagination
   */
  async getAllVehicles(
    userId: string,
    page: number = 1,
    limit: number = 20
  ): Promise<VehicleListResult> {
    const [vehicles, total] = await Promise.all([
      Vehicle.findByUser(userId, { page, limit }),
      Vehicle.countByUser(userId),
    ]);

    return {
      data: vehicles,
      pagination: buildPaginationMeta(page, limit, total),
    };
  }

  /**
   * Get a single vehicle by ID (with ownership check)
   */
  async getVehicleById(userId: string, vehicleId: string): Promise<IVehicle> {
    const vehicle = await Vehicle.findByUserAndId(userId, vehicleId);

    if (!vehicle) {
      throw createError('Vehicle not found', 404);
    }

    return vehicle;
  }

  /**
   * Create a new vehicle
   */
  async createVehicle(userId: string, data: VehicleCreateData): Promise<IVehicle> {
    const vehicle = await Vehicle.create({
      userId,
      name: data.name,
      make: data.make,
      vehicleModel: data.vehicleModel,
      year: data.year,
      mileage: data.mileage,
    });

    return vehicle;
  }

  /**
   * Update a vehicle (with ownership check)
   */
  async updateVehicle(
    userId: string,
    vehicleId: string,
    data: VehicleUpdateData
  ): Promise<IVehicle> {
    const vehicle = await Vehicle.findByUserAndId(userId, vehicleId);

    if (!vehicle) {
      throw createError('Vehicle not found', 404);
    }

    // Update only provided fields using set() to avoid property name conflicts
    if (data.name !== undefined) vehicle.set('name', data.name);
    if (data.make !== undefined) vehicle.set('make', data.make);
    if (data.vehicleModel !== undefined) vehicle.set('vehicleModel', data.vehicleModel);
    if (data.year !== undefined) vehicle.set('year', data.year);
    if (data.mileage !== undefined) vehicle.set('mileage', data.mileage);

    await vehicle.save();
    return vehicle;
  }

  /**
   * Delete a vehicle (with ownership check)
   */
  async deleteVehicle(userId: string, vehicleId: string): Promise<void> {
    const vehicle = await Vehicle.findByUserAndId(userId, vehicleId);

    if (!vehicle) {
      throw createError('Vehicle not found', 404);
    }

    await Vehicle.deleteOne({ _id: vehicleId, userId });
  }
}

// Export singleton instance
export const vehicleService = new VehicleService();