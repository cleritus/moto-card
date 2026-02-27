import mongoose, { Schema, Document } from 'mongoose';
import bcrypt from 'bcrypt';

// Interface for TypeScript
export interface IUser extends Document {
  email: string;
  passwordHash: string;
  createdAt: Date;
  refreshTokens: string[];
  comparePassword(candidate: string): Promise<boolean>;
}

// Interface for static methods
interface IUserModel extends mongoose.Model<IUser> {
  findByEmail(email: string): Promise<IUser | null>;
}

// Schema definition
const UserSchema = new Schema<IUser, IUserModel>({
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^.+@.+\..+$/, 'Please enter a valid email'],
  },
  passwordHash: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters'],
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  refreshTokens: {
    type: [String],
    default: [],
  },
});

// Methods (instance)
UserSchema.methods.comparePassword = async function (candidate: string): Promise<boolean> {
  return bcrypt.compare(candidate, this.passwordHash);
};

// Statics (model-level)
UserSchema.statics.findByEmail = function (email: string) {
  return this.findOne({ email: email.toLowerCase() });
};

// Virtuals
UserSchema.virtual('id').get(function () {
  return this._id.toHexString();
});

// Transform JSON output
UserSchema.set('toJSON', {
  virtuals: true,
  transform: (_doc, ret) => {
    delete ret._id;
    delete ret.__v;
    delete ret.passwordHash; // Never expose password
    delete ret.refreshTokens; // Never expose refresh tokens
    return ret;
  },
});

export default mongoose.model<IUser, IUserModel>('User', UserSchema);
