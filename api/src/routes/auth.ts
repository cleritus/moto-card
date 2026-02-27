import { Router } from 'express';
import { authController } from '../controllers/authController';
import { authenticate } from '../middleware/auth';
import { validateRegister, validateLogin, validateRefresh, validateLogout } from '../utils/validation';

const router = Router();

// Public routes (bez autentykacji)
router.post('/register', ...validateRegister, authController.register);
router.post('/login', ...validateLogin, authController.login);
router.post('/refresh', ...validateRefresh, authController.refresh);

// Protected routes (wymagają autentykacji)
router.post('/logout', authenticate, ...validateLogout, authController.logout);
router.get('/me', authenticate, authController.me);

export default router;
