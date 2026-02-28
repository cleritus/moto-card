import mongoose, { Schema, Types, Document } from 'mongoose';

// Reminder types
export enum ReminderType {
  DATE = 'date',
  MILEAGE = 'mileage',
}

// Filter options for reminders
export enum ReminderFilter {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  ALL = 'all',
}

// Interface for Reminder document
export interface IReminder extends Document {
  vehicleId: Types.ObjectId;
  title: string;
  type: ReminderType;
  dueDate?: Date;
  dueMileage?: number;
  isCompleted: boolean;
  completedAt?: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Interface for static methods
interface IReminderModel extends mongoose.Model<IReminder> {
  findByVehicle(
    vehicleId: string,
    options?: { page?: number; limit?: number; filter?: ReminderFilter }
  ): Promise<IReminder[]>;
  findByVehicleAndId(vehicleId: string, reminderId: string): Promise<IReminder | null>;
  countByVehicle(vehicleId: string, filter?: ReminderFilter): Promise<number>;
}

// Schema definition
const ReminderSchema = new Schema<IReminder, IReminderModel>(
  {
    vehicleId: {
      type: Schema.Types.ObjectId,
      ref: 'Vehicle',
      required: [true, 'Vehicle ID is required'],
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      maxlength: [200, 'Title cannot exceed 200 characters'],
    },
    type: {
      type: String,
      required: [true, 'Type is required'],
      enum: {
        values: [ReminderType.DATE, ReminderType.MILEAGE],
        message: 'Type must be either "date" or "mileage"',
      },
      index: true,
    },
    dueDate: {
      type: Date,
      default: undefined,
      index: true,
    },
    dueMileage: {
      type: Number,
      min: [0, 'Due mileage cannot be negative'],
      default: undefined,
      index: true,
    },
    isCompleted: {
      type: Boolean,
      required: true,
      default: false,
      index: true,
    },
    completedAt: {
      type: Date,
      default: undefined,
    },
    notes: {
      type: String,
      trim: true,
      maxlength: [500, 'Notes cannot exceed 500 characters'],
      default: undefined,
    },
  },
  {
    timestamps: true,
  }
);

// Compound indexes for efficient querying
ReminderSchema.index({ vehicleId: 1, isCompleted: 1, dueDate: 1 });
ReminderSchema.index({ vehicleId: 1, isCompleted: 1, dueMileage: 1 });

// Statics (model-level)
ReminderSchema.statics.findByVehicle = function (
  vehicleId: string,
  options?: { page?: number; limit?: number; filter?: ReminderFilter }
) {
  const query: Record<string, unknown> = { vehicleId };

  // Apply filter
  if (options && options.filter) {
    switch (options.filter) {
      case ReminderFilter.ACTIVE:
        query.isCompleted = false;
        break;
      case ReminderFilter.COMPLETED:
        query.isCompleted = true;
        break;
      case ReminderFilter.ALL:
      default:
        // No filter
        break;
    }
  }

  // Sort based on type (date vs mileage)
  const sortQuery: Record<string, 1 | -1> = { isCompleted: 1 }; // Active reminders first
  if (options?.filter === ReminderFilter.COMPLETED) {
    sortQuery.completedAt = -1; // Most recently completed first
    delete sortQuery.createdAt;
  } else {
    sortQuery.createdAt = -1; // Active first, newest first
  }

  let mongooseQuery = this.find(query).sort(sortQuery);

  // Apply pagination
  if (options && options.page !== undefined && options.limit !== undefined) {
    const skip = (options.page - 1) * options.limit;
    mongooseQuery = mongooseQuery.skip(skip).limit(options.limit);
  }

  return mongooseQuery;
};

ReminderSchema.statics.findByVehicleAndId = function (
  vehicleId: string,
  reminderId: string
) {
  return this.findOne({ _id: reminderId, vehicleId });
};

ReminderSchema.statics.countByVehicle = function (
  vehicleId: string,
  filter?: ReminderFilter
) {
  const query: Record<string, unknown> = { vehicleId };

  if (filter) {
    switch (filter) {
      case ReminderFilter.ACTIVE:
        query.isCompleted = false;
        break;
      case ReminderFilter.COMPLETED:
        query.isCompleted = true;
        break;
      case ReminderFilter.ALL:
      default:
        // No filter
        break;
    }
  }

  return this.countDocuments(query);
};

// Virtuals
ReminderSchema.virtual('id').get(function () {
  return this._id.toHexString();
});

// Transform JSON output
ReminderSchema.set('toJSON', {
  virtuals: true,
  transform: function (_doc, ret) {
    const transformed = { ...ret } as Record<string, unknown>;
    delete transformed._id;
    delete transformed.__v;
    return transformed;
  },
});

export default mongoose.model<IReminder, IReminderModel>('Reminder', ReminderSchema);