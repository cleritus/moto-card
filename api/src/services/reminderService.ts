import Reminder, { IReminder, ReminderFilter } from '../models/Reminder';
import Vehicle, { IVehicle } from '../models/Vehicle';
import { createError } from '../middleware/errorHandler';
import { buildPaginationMeta, PaginationMeta } from '../utils/pagination';

export interface ReminderCreateData {
  title: string;
  type: 'date' | 'mileage';
  dueDate?: Date;
  dueMileage?: number;
  intervalKm?: number;
  lastDoneMileage?: number;
  notes?: string;
}

export interface ReminderUpdateData {
  title?: string;
  type?: 'date' | 'mileage';
  dueDate?: Date;
  dueMileage?: number;
  intervalKm?: number;
  lastDoneMileage?: number;
  isCompleted?: boolean;
  notes?: string;
}

export interface ReminderListResult {
  data: IReminder[];
  pagination: PaginationMeta;
}

export class ReminderService {
  /**
   * Verify that the user owns the vehicle (returns the vehicle so callers
   * that need its current mileage don't have to re-query)
   */
  private async verifyVehicleOwnership(userId: string, vehicleId: string): Promise<IVehicle> {
    const vehicle = await Vehicle.findByUserAndId(userId, vehicleId);
    if (!vehicle) {
      throw createError('Vehicle not found or access denied', 404);
    }
    return vehicle;
  }

  /**
   * Completion bookkeeping for mileage-type reminders:
   * record the odometer reading at completion time and roll the due
   * mileage forward by the maintenance interval.
   * No-ops for date reminders, for vehicles without a known mileage,
   * and for reminders that have no interval set (e.g. ones created
   * before intervalKm existed).
   */
  private applyMileageCompletion(reminder: IReminder, vehicle: IVehicle): void {
    if (reminder.type !== 'mileage') return;
    if (vehicle.mileage === undefined || vehicle.mileage === null) return;

    reminder.set('lastDoneMileage', vehicle.mileage);

    if (reminder.intervalKm !== undefined && reminder.intervalKm !== null) {
      reminder.set('dueMileage', vehicle.mileage + reminder.intervalKm);
    }
  }

  /**
   * Get all reminders for a vehicle with pagination and filter
   */
  async getAllReminders(
    userId: string,
    vehicleId: string,
    page: number = 1,
    limit: number = 20,
    filter: ReminderFilter = ReminderFilter.ALL
  ): Promise<ReminderListResult> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const [reminders, total] = await Promise.all([
      Reminder.findByVehicle(vehicleId, { page, limit, filter }),
      Reminder.countByVehicle(vehicleId, filter),
    ]);

    return {
      data: reminders,
      pagination: buildPaginationMeta(page, limit, total),
    };
  }

  /**
   * Get a single reminder by ID (with ownership check)
   */
  async getReminderById(userId: string, vehicleId: string, reminderId: string): Promise<IReminder> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const reminder = await Reminder.findByVehicleAndId(vehicleId, reminderId);

    if (!reminder) {
      throw createError('Reminder not found', 404);
    }

    return reminder;
  }

  /**
   * Create a new reminder
   */
  async createReminder(
    userId: string,
    vehicleId: string,
    data: ReminderCreateData
  ): Promise<IReminder> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    // Validate that dueDate is provided for date-type reminders
    if (data.type === 'date' && !data.dueDate) {
      throw createError('dueDate is required for date-type reminders', 400);
    }

    // Validate that dueMileage is provided for mileage-type reminders
    if (data.type === 'mileage' && data.dueMileage === undefined) {
      throw createError('dueMileage is required for mileage-type reminders', 400);
    }

    const reminder = await Reminder.create({
      vehicleId,
      title: data.title,
      type: data.type,
      dueDate: data.dueDate,
      dueMileage: data.dueMileage,
      intervalKm: data.type === 'mileage' ? data.intervalKm : undefined,
      lastDoneMileage: data.type === 'mileage' ? data.lastDoneMileage : undefined,
      isCompleted: false,
      notes: data.notes,
    });

    return reminder;
  }

  /**
   * Update a reminder (with ownership check)
   */
  async updateReminder(
    userId: string,
    vehicleId: string,
    reminderId: string,
    data: ReminderUpdateData
  ): Promise<IReminder> {
    const vehicle = await this.verifyVehicleOwnership(userId, vehicleId);

    const reminder = await Reminder.findByVehicleAndId(vehicleId, reminderId);

    if (!reminder) {
      throw createError('Reminder not found', 404);
    }

    const wasCompleted = reminder.isCompleted;

    // Update only provided fields
    if (data.title !== undefined) reminder.set('title', data.title);
    if (data.type !== undefined) reminder.set('type', data.type);
    if (data.dueDate !== undefined) reminder.set('dueDate', data.dueDate);
    if (data.dueMileage !== undefined) reminder.set('dueMileage', data.dueMileage);
    if (data.intervalKm !== undefined) reminder.set('intervalKm', data.intervalKm);
    if (data.lastDoneMileage !== undefined) {
      reminder.set('lastDoneMileage', data.lastDoneMileage);
    }
    if (data.isCompleted !== undefined) {
      reminder.set('isCompleted', data.isCompleted);
      // Set or clear completedAt based on isCompleted
      if (data.isCompleted && !reminder.completedAt) {
        reminder.set('completedAt', new Date());
      } else if (!data.isCompleted) {
        reminder.set('completedAt', undefined);
      }
    }
    if (data.notes !== undefined) reminder.set('notes', data.notes);

    // Same completion bookkeeping as the dedicated complete endpoint, but only
    // on the active -> completed transition so plain edits of an already
    // completed reminder don't keep rolling the due mileage forward.
    if (data.isCompleted === true && !wasCompleted) {
      this.applyMileageCompletion(reminder, vehicle);
    }

    await reminder.save();
    return reminder;
  }

  /**
   * Delete a reminder (with ownership check)
   */
  async deleteReminder(userId: string, vehicleId: string, reminderId: string): Promise<void> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const reminder = await Reminder.findByVehicleAndId(vehicleId, reminderId);

    if (!reminder) {
      throw createError('Reminder not found', 404);
    }

    await Reminder.deleteOne({ _id: reminderId, vehicleId });
  }

  /**
   * Mark a reminder as completed
   */
  async markAsCompleted(userId: string, vehicleId: string, reminderId: string): Promise<IReminder> {
    const vehicle = await this.verifyVehicleOwnership(userId, vehicleId);

    const reminder = await Reminder.findByVehicleAndId(vehicleId, reminderId);

    if (!reminder) {
      throw createError('Reminder not found', 404);
    }

    if (reminder.isCompleted) {
      throw createError('Reminder is already completed', 400);
    }

    reminder.set('isCompleted', true);
    reminder.set('completedAt', new Date());
    this.applyMileageCompletion(reminder, vehicle);

    await reminder.save();
    return reminder;
  }

  /**
   * Mark a reminder as not completed (undo completion)
   */
  async markAsIncomplete(userId: string, vehicleId: string, reminderId: string): Promise<IReminder> {
    await this.verifyVehicleOwnership(userId, vehicleId);

    const reminder = await Reminder.findByVehicleAndId(vehicleId, reminderId);

    if (!reminder) {
      throw createError('Reminder not found', 404);
    }

    if (!reminder.isCompleted) {
      throw createError('Reminder is not completed', 400);
    }

    reminder.set('isCompleted', false);
    reminder.set('completedAt', undefined);

    await reminder.save();
    return reminder;
  }
}

// Export singleton instance
export const reminderService = new ReminderService();