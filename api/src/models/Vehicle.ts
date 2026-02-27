import mongoose, { Schema, Types, Document } from 'mongoose';

// Interface for Vehicle document
export interface IVehicle extends Document {
  userId: Types.ObjectId;
  name: string;
  make: string;
  vehicleModel: string;  // Renamed from 'model' to avoid conflict with Document.model
  year: number;
  mileage?: number;
  createdAt: Date;
  updatedAt: Date;
}

// Interface for static methods
interface IVehicleModel extends mongoose.Model<IVehicle> {
  findByUser(userId: string): Promise<IVehicle[]>;
  findByUserAndId(userId: string, vehicleId: string): Promise<IVehicle | null>;
}

// Schema definition
const VehicleSchema = new Schema<IVehicle, IVehicleModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Vehicle name is required'],
      trim: true,
      maxlength: [100, 'Name cannot exceed 100 characters'],
    },
    make: {
      type: String,
      required: [true, 'Make is required'],
      trim: true,
      maxlength: [50, 'Make cannot exceed 50 characters'],
    },
    vehicleModel: {
      type: String,
      required: [true, 'Model is required'],
      trim: true,
      maxlength: [50, 'Model cannot exceed 50 characters'],
    },
    year: {
      type: Number,
      required: [true, 'Year is required'],
      min: [1900, 'Year must be 1900 or later'],
      max: [new Date().getFullYear() + 1, 'Year cannot be in the future'],
    },
    mileage: {
      type: Number,
      min: [0, 'Mileage cannot be negative'],
      default: undefined,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for userId + name
VehicleSchema.index({ userId: 1, name: 1 });

// Statics (model-level)
VehicleSchema.statics.findByUser = function (userId: string) {
  return this.find({ userId }).sort({ createdAt: -1 });
};

VehicleSchema.statics.findByUserAndId = function (userId: string, vehicleId: string) {
  return this.findOne({ _id: vehicleId, userId });
};

// Virtuals
VehicleSchema.virtual('id').get(function () {
  return this._id.toHexString();
});

// Transform JSON output
VehicleSchema.set('toJSON', {
  virtuals: true,
  transform: function (_doc, ret) {
    const transformed = { ...ret } as Record<string, unknown>;
    delete transformed._id;
    delete transformed.__v;
    return transformed;
  },
});

export default mongoose.model<IVehicle, IVehicleModel>('Vehicle', VehicleSchema);
