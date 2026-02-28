import mongoose, { Schema, Types, Document } from 'mongoose';

// Interface for FuelLog document
export interface IFuelLog extends Document {
  vehicleId: Types.ObjectId;
  date: Date;
  mileage: number;
  fuelAmount: number;
  totalCost: number;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Interface for static methods
interface IFuelLogModel extends mongoose.Model<IFuelLog> {
  findByVehicle(vehicleId: string, options?: { page?: number; limit?: number }): Promise<IFuelLog[]>;
  findByVehicleAndId(vehicleId: string, fuelLogId: string): Promise<IFuelLog | null>;
  countByVehicle(vehicleId: string): Promise<number>;
}

// Schema definition
const FuelLogSchema = new Schema<IFuelLog, IFuelLogModel>(
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
    fuelAmount: {
      type: Number,
      required: [true, 'Fuel amount is required'],
      min: [0, 'Fuel amount cannot be negative'],
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
FuelLogSchema.index({ vehicleId: 1, date: -1 });

// Statics (model-level)
FuelLogSchema.statics.findByVehicle = function (vehicleId: string, options?: { page?: number; limit?: number }) {
  let query = this.find({ vehicleId }).sort({ date: -1 });

  if (options && options.page !== undefined && options.limit !== undefined) {
    const skip = (options.page - 1) * options.limit;
    query = query.skip(skip).limit(options.limit);
  }

  return query;
};

FuelLogSchema.statics.findByVehicleAndId = function (vehicleId: string, fuelLogId: string) {
  return this.findOne({ _id: fuelLogId, vehicleId });
};

FuelLogSchema.statics.countByVehicle = function (vehicleId: string) {
  return this.countDocuments({ vehicleId });
};

// Virtuals
FuelLogSchema.virtual('id').get(function () {
  return this._id.toHexString();
});

// Transform JSON output
FuelLogSchema.set('toJSON', {
  virtuals: true,
  transform: function (_doc, ret) {
    const transformed = { ...ret } as Record<string, unknown>;
    delete transformed._id;
    delete transformed.__v;
    return transformed;
  },
});

export default mongoose.model<IFuelLog, IFuelLogModel>('FuelLog', FuelLogSchema);
