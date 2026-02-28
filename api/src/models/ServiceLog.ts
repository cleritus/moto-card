import mongoose, { Schema, Types, Document } from 'mongoose';

// Interface for ServiceLog document
export interface IServiceLog extends Document {
  vehicleId: Types.ObjectId;
  date: Date;
  mileage: number;
  serviceType: string;
  description?: string;
  mechanic?: string;
  totalCost: number;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Interface for static methods
interface IServiceLogModel extends mongoose.Model<IServiceLog> {
  findByVehicle(
    vehicleId: string,
    options?: { page?: number; limit?: number }
  ): Promise<IServiceLog[]>;
  findByVehicleAndId(vehicleId: string, serviceLogId: string): Promise<IServiceLog | null>;
  countByVehicle(vehicleId: string): Promise<number>;
}

// Schema definition
const ServiceLogSchema = new Schema<IServiceLog, IServiceLogModel>(
  {
    vehicleId: {
      type: Schema.Types.ObjectId,
      ref: 'Vehicle',
      required: [true, 'Vehicle ID is required'],
      index: true,
    },
    date: {
      type: Date,
      required: [true, 'Date is required'],
      default: Date.now,
      index: true,
    },
    mileage: {
      type: Number,
      required: [true, 'Mileage is required'],
      min: [0, 'Mileage cannot be negative'],
    },
    serviceType: {
      type: String,
      required: [true, 'Service type is required'],
      trim: true,
      maxlength: [100, 'Service type cannot exceed 100 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [500, 'Description cannot exceed 500 characters'],
      default: undefined,
    },
    mechanic: {
      type: String,
      trim: true,
      maxlength: [100, 'Mechanic name cannot exceed 100 characters'],
      default: undefined,
    },
    totalCost: {
      type: Number,
      required: [true, 'Total cost is required'],
      min: [0, 'Total cost cannot be negative'],
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

// Compound index for vehicleId + date (for efficient querying and sorting)
ServiceLogSchema.index({ vehicleId: 1, date: -1 });

// Statics (model-level)
ServiceLogSchema.statics.findByVehicle = function (
  vehicleId: string,
  options?: { page?: number; limit?: number }
) {
  let query = this.find({ vehicleId }).sort({ date: -1 });

  if (options && options.page !== undefined && options.limit !== undefined) {
    const skip = (options.page - 1) * options.limit;
    query = query.skip(skip).limit(options.limit);
  }

  return query;
};

ServiceLogSchema.statics.findByVehicleAndId = function (
  vehicleId: string,
  serviceLogId: string
) {
  return this.findOne({ _id: serviceLogId, vehicleId });
};

ServiceLogSchema.statics.countByVehicle = function (vehicleId: string) {
  return this.countDocuments({ vehicleId });
};

// Virtuals
ServiceLogSchema.virtual('id').get(function () {
  return this._id.toHexString();
});

// Transform JSON output
ServiceLogSchema.set('toJSON', {
  virtuals: true,
  transform: function (_doc, ret) {
    const transformed = { ...ret } as Record<string, unknown>;
    delete transformed._id;
    delete transformed.__v;
    return transformed;
  },
});

export default mongoose.model<IServiceLog, IServiceLogModel>('ServiceLog', ServiceLogSchema);