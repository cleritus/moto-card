import { Router } from 'express';
import { authController } from '../controllers/authController';
import { authenticate } from '../middleware/auth';

const router = Router();

// Public routes (bez autentykacji)
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/refresh', authController.refresh);

// Protected routes (wymagają autentykacji)
router.post('/logout', authenticate, authController.logout);
router.get('/me', authenticate, authController.me);

export default router;
