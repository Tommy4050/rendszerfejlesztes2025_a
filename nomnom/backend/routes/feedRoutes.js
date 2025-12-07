import { Router } from "express";
import { getFeed, getDiscoverFeed } from "../controllers/feedController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = Router();

router.get("/", protect, getFeed);
router.get("/discover", protect, getDiscoverFeed);

export default router;
