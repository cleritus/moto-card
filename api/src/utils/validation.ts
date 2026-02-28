import { body, validationResult, ValidationChain } from 'express-validator';
import { Request, Response, NextFunction } from 'express';
import { createError } from '../middleware/errorHandler';

// Validation result handler middleware
export const handleValidationErrors = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const messages = errors.array().map((err) => err.msg).join(', ');
    throw createError(`Validation error: ${messages}`, 400);
  }
  next();
};

// Register validation
export const validateRegister: ValidationChain[] = [
  body('email')
    .isEmail()
    .withMessage('Please enter a valid email')
    .normalizeEmail()
    .trim(),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters')
    .trim(),
  handleValidationErrors as unknown as ValidationChain,
];

// Login validation
export const validateLogin: ValidationChain[] = [
  body('email')
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please enter a valid email')
    .normalizeEmail()
    .trim(),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .trim(),
  handleValidationErrors as unknown as ValidationChain,
];

// Refresh token validation
export const validateRefresh: ValidationChain[] = [
  body('refreshToken')
    .notEmpty()
    .withMessage('Refresh token is required')
    .trim(),
  handleValidationErrors as unknown as ValidationChain,
];

// Logout validation
export const validateLogout: ValidationChain[] = [
  body('refreshToken')
    .notEmpty()
    .withMessage('Refresh token is required')
    .trim(),
  handleValidationErrors as unknown as ValidationChain,
];

// Vehicle validation
export const validateVehicleCreate: ValidationChain[] = [
  body('name')
    .notEmpty()
    .withMessage('Vehicle name is required')
    .trim(),
  body('make')
    .notEmpty()
    .withMessage('Make is required')
    .trim(),
  body('vehicleModel')
    .notEmpty()
    .withMessage('Model is required')
    .trim(),
  body('year')
    .isInt({ min: 1900, max: new Date().getFullYear() + 1 })
    .withMessage('Please enter a valid year')
    .toInt(),
  body('mileage')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Mileage must be a positive number')
    .toInt(),
  handleValidationErrors as unknown as ValidationChain,
];

// Vehicle update validation (all fields optional)
export const validateVehicleUpdate: ValidationChain[] = [
  body('name')
    .optional()
    .notEmpty()
    .withMessage('Vehicle name cannot be empty')
    .trim(),
  body('make')
    .optional()
    .notEmpty()
    .withMessage('Make cannot be empty')
    .trim(),
  body('vehicleModel')
    .optional()
    .notEmpty()
    .withMessage('Model cannot be empty')
    .trim(),
  body('year')
    .optional()
    .isInt({ min: 1900, max: new Date().getFullYear() + 1 })
    .withMessage('Please enter a valid year')
    .toInt(),
  body('mileage')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Mileage must be a positive number')
    .toInt(),
  handleValidationErrors as unknown as ValidationChain,
];

// Fuel log validation
export const validateFuelLogCreate: ValidationChain[] = [
  body('date')
    .optional()
    .isISO8601()
    .withMessage('Please enter a valid date')
    .toDate(),
  body('mileage')
    .isInt({ min: 0 })
    .withMessage('Mileage must be a positive number')
    .toInt(),
  body('fuelAmount')
    .isFloat({ min: 0 })
    .withMessage('Fuel amount must be a positive number')
    .toFloat(),
  body('totalCost')
    .isFloat({ min: 0 })
    .withMessage('Total cost must be a positive number')
    .toFloat(),
  handleValidationErrors as unknown as ValidationChain,
];

// Fuel log update validation (all fields optional)
export const validateFuelLogUpdate: ValidationChain[] = [
  body('date')
    .optional()
    .isISO8601()
    .withMessage('Please enter a valid date')
    .toDate(),
  body('mileage')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Mileage must be a positive number')
    .toInt(),
  body('fuelAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Fuel amount must be a positive number')
    .toFloat(),
  body('totalCost')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Total cost must be a positive number')
    .toFloat(),
  body('notes')
    .optional()
    .trim(),
  handleValidationErrors as unknown as ValidationChain,
];

// Service log validation
export const validateServiceLogCreate: ValidationChain[] = [
  body('date')
    .optional()
    .isISO8601()
    .withMessage('Please enter a valid date')
    .toDate(),
  body('mileage')
    .isInt({ min: 0 })
    .withMessage('Mileage must be a positive number')
    .toInt(),
  body('serviceType')
    .notEmpty()
    .withMessage('Service type is required')
    .trim(),
  body('totalCost')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Total cost must be a positive number')
    .toFloat(),
  handleValidationErrors as unknown as ValidationChain,
];

// Service log update validation (all fields optional)
export const validateServiceLogUpdate: ValidationChain[] = [
  body('date')
    .optional()
    .isISO8601()
    .withMessage('Please enter a valid date')
    .toDate(),
  body('mileage')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Mileage must be a positive number')
    .toInt(),
  body('serviceType')
    .optional()
    .notEmpty()
    .withMessage('Service type cannot be empty')
    .trim(),
  body('description')
    .optional()
    .trim(),
  body('mechanic')
    .optional()
    .trim(),
  body('totalCost')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Total cost must be a positive number')
    .toFloat(),
  body('notes')
    .optional()
    .trim(),
  handleValidationErrors as unknown as ValidationChain,
];

// Reminder validation
export const validateReminderCreate: ValidationChain[] = [
  body('title')
    .notEmpty()
    .withMessage('Title is required')
    .trim(),
  body('type')
    .isIn(['date', 'mileage'])
    .withMessage('Type must be either "date" or "mileage"'),
  body('dueDate')
    .optional()
    .isISO8601()
    .withMessage('Please enter a valid date')
    .toDate(),
  body('dueMileage')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Due mileage must be a positive number')
    .toInt(),
  handleValidationErrors as unknown as ValidationChain,
];

// Reminder update validation (all fields optional)
export const validateReminderUpdate: ValidationChain[] = [
  body('title')
    .optional()
    .notEmpty()
    .withMessage('Title cannot be empty')
    .trim(),
  body('type')
    .optional()
    .isIn(['date', 'mileage'])
    .withMessage('Type must be either "date" or "mileage"'),
  body('dueDate')
    .optional()
    .isISO8601()
    .withMessage('Please enter a valid date')
    .toDate(),
  body('dueMileage')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Due mileage must be a positive number')
    .toInt(),
  body('isCompleted')
    .optional()
    .isBoolean()
    .withMessage('isCompleted must be a boolean')
    .toBoolean(),
  body('notes')
    .optional()
    .trim(),
  handleValidationErrors as unknown as ValidationChain,
];