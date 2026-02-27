import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { authService } from '../services/authService';
import { createError } from '../middleware/errorHandler';

export const authController = {
  register: asyncHandler(async (req: Request, res: Response) => {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      throw createError('Email and password are required', 400);
    }

    if (password.length < 6) {
      throw createError('Password must be at least 6 characters', 400);
    }

    // Validate email format
    const emailRegex = /^\S+@\S+\.\S+$/;
    if (!emailRegex.test(email)) {
      throw createError('Please enter a valid email', 400);
    }

    // Call service
    const { user, tokens } = await authService.register(email, password);

    // Response
    res.status(201).json({
      success: true,
      data: { user, tokens },
    });
  }),

  login: asyncHandler(async (req: Request, res: Response) => {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      throw createError('Email and password are required', 400);
    }

    // Call service
    const { user, tokens } = await authService.login(email, password);

    // Response
    res.status(200).json({
      success: true,
      data: { user, tokens },
    });
  }),

  refresh: asyncHandler(async (req: Request, res: Response) => {
    const { refreshToken } = req.body;

    // Validation
    if (!refreshToken) {
      throw createError('Refresh token is required', 400);
    }

    // Call service
    const tokens = await authService.refreshTokens(refreshToken);

    // Response
    res.status(200).json({
      success: true,
      data: { tokens },
    });
  }),

  logout: asyncHandler(async (req: Request, res: Response) => {
    const { refreshToken } = req.body;
    const userId = req.user?.userId;

    // Validation
    if (!refreshToken) {
      throw createError('Refresh token is required', 400);
    }

    if (!userId) {
      throw createError('User not authenticated', 401);
    }

    // Call service
    await authService.logout(userId, refreshToken);

    // Response
    res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  }),

  me: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;

    // req.user is set by authenticate middleware
    if (!user) {
      throw createError('User not authenticated', 401);
    }

    // Response
    res.status(200).json({
      success: true,
      data: { user },
    });
  }),
};
