import ServiceLog, { IServiceLog } from '../models/ServiceLog';
import Vehicle from '../models/Vehicle';
import { createError } from '../middleware/errorHandler';
import { buildPaginationMeta, PaginationMeta } from '../utils/pagination';

export interface ServiceLogCreateData {
  date?: Date;
  mileage: number;
  serviceType: string;
  description?: string;
  mechanic?: string;
  totalCost: number;
  notes?: string;
}

export interface ServiceLogUpdateData {
  date?: Date;
  mileage?: number;
  serviceType?: string;
  description?: string;
  mechanic?: string;
  totalCost?: number;
  notes?: string;
}

export interface ServiceLogListResult {
  data: IServiceLog[];
  pagination: PaginationMeta;
}

export class ServiceLogService {
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
   * Get all service logs for a vehicle with pagination
   */
  async getAllServiceLogs(
    userId: string,
    vehicleId: string,
    page: number = 1,
    limit: number = 20
  ): Promise<ServiceLogListResult> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const [serviceLogs, total] = await Promise.all([
      ServiceLog.findByVehicle(vehicleId, { page, limit }),
      ServiceLog.countByVehicle(vehicleId),
    ]);

    return {
      data: serviceLogs,
      pagination: buildPaginationMeta(page, limit, total),
    };
  }

  /**
   * Get a single service log by ID (with ownership check)
   */
  async getServiceLogById(
    userId: string,
    vehicleId: string,
    serviceLogId: string
  ): Promise<IServiceLog> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const serviceLog = await ServiceLog.findByVehicleAndId(vehicleId, serviceLogId);

    if (!serviceLog) {
      throw createError('Service log not found', 404);
    }

    return serviceLog;
  }

  /**
   * Create a new service log
   */
  async createServiceLog(
    userId: string,
    vehicleId: string,
    data: ServiceLogCreateData
  ): Promise<IServiceLog> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const serviceLog = await ServiceLog.create({
      vehicleId,
      date: data.date || new Date(),
      mileage: data.mileage,
      serviceType: data.serviceType,
      description: data.description,
      mechanic: data.mechanic,
      totalCost: data.totalCost,
      notes: data.notes,
    });

    return serviceLog;
  }

  /**
   * Update a service log (with ownership check)
   */
  async updateServiceLog(
    userId: string,
    vehicleId: string,
    serviceLogId: string,
    data: ServiceLogUpdateData
  ): Promise<IServiceLog> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const serviceLog = await ServiceLog.findByVehicleAndId(vehicleId, serviceLogId);

    if (!serviceLog) {
      throw createError('Service log not found', 404);
    }

    // Update only provided fields
    if (data.date !== undefined) serviceLog.set('date', data.date);
    if (data.mileage !== undefined) serviceLog.set('mileage', data.mileage);
    if (data.serviceType !== undefined) serviceLog.set('serviceType', data.serviceType);
    if (data.description !== undefined) serviceLog.set('description', data.description);
    if (data.mechanic !== undefined) serviceLog.set('mechanic', data.mechanic);
    if (data.totalCost !== undefined) serviceLog.set('totalCost', data.totalCost);
    if (data.notes !== undefined) serviceLog.set('notes', data.notes);

    await serviceLog.save();
    return serviceLog;
  }

  /**
   * Delete a service log (with ownership check)
   */
  async deleteServiceLog(userId: string, vehicleId: string, serviceLogId: string): Promise<void> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const serviceLog = await ServiceLog.findByVehicleAndId(vehicleId, serviceLogId);

    if (!serviceLog) {
      throw createError('Service log not found', 404);
    }

    await ServiceLog.deleteOne({ _id: serviceLogId, vehicleId });
  }
}

// Export singleton instance
export const serviceLogService = new ServiceLogService();