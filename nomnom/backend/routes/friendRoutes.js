import { Router } from "express";
import { followUser, unfollowUser, listFollowing, listFollowers } from "../controllers/friendController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = Router();

router.post("/:id/follow", protect, followUser);
router.post("/:id/unfollow", protect, unfollowUser);
router.get("/following", protect, listFollowing);
router.get("/followers", protect, listFollowers);

export default router;