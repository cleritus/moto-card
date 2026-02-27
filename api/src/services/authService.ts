import bcrypt from 'bcrypt';
import User, { IUser } from '../models/User';
import { generateTokens, verifyRefreshToken, AuthTokens } from '../utils/jwt';
import { createError } from '../middleware/errorHandler';

export class AuthService {
  /**
   * Register a new user
   * 1. Check if user exists
   * 2. Hash password
   * 3. Create user
   * 4. Generate tokens
   * 5. Save refresh token
   * 6. Return user and tokens
   */
  async register(email: string, password: string): Promise<{ user: IUser; tokens: AuthTokens }> {
    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      throw createError('User already exists', 409);
    }

    // Hash password with bcrypt (salt rounds: 10)
    const passwordHash = await bcrypt.hash(password, 10);

    // Create new user
    const user = await User.create({
      email: email.toLowerCase(),
      passwordHash,
      refreshTokens: [],
    });

    // Generate JWT tokens
    const tokens = generateTokens(user);

    // Save refresh token to user (limit handled in array)
    user.refreshTokens.push(tokens.refreshToken);
    await user.save();

    return { user, tokens };
  }

  /**
   * Login user
   * 1. Find user by email
   * 2. Compare password
   * 3. Generate tokens
   * 4. Add refresh token (limit to 5, FIFO)
   * 5. Save user
   * 6. Return user and tokens
   */
  async login(email: string, password: string): Promise<{ user: IUser; tokens: AuthTokens }> {
    // Find user by email
    const user = await User.findByEmail(email);

    // Don't reveal if email doesn't exist (security best practice)
    if (!user) {
      throw createError('Invalid credentials', 401);
    }

    // Compare password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      throw createError('Invalid credentials', 401);
    }

    // Generate JWT tokens
    const tokens = generateTokens(user);

    // Add refresh token to user.refreshTokens
    user.refreshTokens.push(tokens.refreshToken);

    // Limit to 5 refresh tokens (FIFO - remove oldest if > 5)
    if (user.refreshTokens.length > 5) {
      user.refreshTokens = user.refreshTokens.slice(-5); // Keep only last 5
    }

    // Save user with new refresh tokens
    await user.save();

    return { user, tokens };
  }

  /**
   * Refresh tokens
   * 1. Verify refresh token
   * 2. Find user by userId from payload
   * 3. Check if refresh token exists in user.refreshTokens
   * 4. Remove old refresh token
   * 5. Generate NEW tokens (rotation)
   * 6. Add new refresh token
   * 7. Save user
   * 8. Return new tokens
   */
  async refreshTokens(refreshToken: string): Promise<AuthTokens> {
    // Verify refresh token
    const payload = verifyRefreshToken(refreshToken);

    // Find user by userId from payload
    const user = await User.findById(payload.userId);
    if (!user) {
      throw createError('Invalid refresh token', 401);
    }

    // Check if refresh token exists in user's refresh tokens
    const tokenIndex = user.refreshTokens.indexOf(refreshToken);
    if (tokenIndex === -1) {
      throw createError('Invalid refresh token', 401);
    }

    // Remove old refresh token from array
    user.refreshTokens.splice(tokenIndex, 1);

    // Generate NEW tokens (rotation - security best practice)
    const newTokens = generateTokens(user);

    // Add new refresh token to array
    user.refreshTokens.push(newTokens.refreshToken);

    // Limit to 5 refresh tokens (FIFO)
    if (user.refreshTokens.length > 5) {
      user.refreshTokens = user.refreshTokens.slice(-5);
    }

    // Save user
    await user.save();

    return newTokens;
  }

  /**
   * Logout user
   * 1. Find user by id
   * 2. Remove refresh token from user.refreshTokens
   * 3. Save user
   */
  async logout(userId: string, refreshToken: string): Promise<void> {
    // Find user by id
    const user = await User.findById(userId);
    if (!user) {
      // Silent fail - user might already be deleted
      return;
    }

    // Remove refresh token from array
    const tokenIndex = user.refreshTokens.indexOf(refreshToken);
    if (tokenIndex !== -1) {
      user.refreshTokens.splice(tokenIndex, 1);
      await user.save();
    }
  }
}

// Export singleton instance
export const authService = new AuthService();
