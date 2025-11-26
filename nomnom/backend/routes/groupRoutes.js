import { Router } from "express";
import { createGroup, joinGroup, getGroupPosts, sharePostToGroup, getMyGroups } from "../controllers/groupController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = Router();

router.get("/", protect, getMyGroups);
router.post("/", protect, createGroup);
router.post("/:id/join", protect, joinGroup);
router.get("/:id/posts", protect, getGroupPosts);
router.post("/:id/share", protect, sharePostToGroup);

export default router;
