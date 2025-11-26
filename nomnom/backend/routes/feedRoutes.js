import { Router } from "express";
import { getFeed, getDiscoverFeed } from "../controllers/feedController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = Router();

// Personalized feed (me + following + my groups)
router.get("/", protect, getFeed);

// Global discover feed (everyone & all groups)
router.get("/discover", protect, getDiscoverFeed);

export default router;
