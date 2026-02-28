import Reminder, { IReminder, ReminderFilter } from '../models/Reminder';
import Vehicle from '../models/Vehicle';
import { createError } from '../middleware/errorHandler';
import { buildPaginationMeta, PaginationMeta } from '../utils/pagination';

export interface ReminderCreateData {
  title: string;
  type: 'date' | 'mileage';
  dueDate?: Date;
  dueMileage?: number;
  notes?: string;
}

export interface ReminderUpdateData {
  title?: string;
  type?: 'date' | 'mileage';
  dueDate?: Date;
  dueMileage?: number;
  isCompleted?: boolean;
  notes?: string;
}

export interface ReminderListResult {
  data: IReminder[];
  pagination: PaginationMeta;
}

export class ReminderService {
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
    await this.verifyVehicleOwnership(userId, vehicleId);

    const reminder = await Reminder.findByVehicleAndId(vehicleId, reminderId);

    if (!reminder) {
      throw createError('Reminder not found', 404);
    }

    // Update only provided fields
    if (data.title !== undefined) reminder.set('title', data.title);
    if (data.type !== undefined) reminder.set('type', data.type);
    if (data.dueDate !== undefined) reminder.set('dueDate', data.dueDate);
    if (data.dueMileage !== undefined) reminder.set('dueMileage', data.dueMileage);
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
    await this.verifyVehicleOwnership(userId, vehicleId);

    const reminder = await Reminder.findByVehicleAndId(vehicleId, reminderId);

    if (!reminder) {
      throw createError('Reminder not found', 404);
    }

    if (reminder.isCompleted) {
      throw createError('Reminder is already completed', 400);
    }

    reminder.set('isCompleted', true);
    reminder.set('completedAt', new Date());

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