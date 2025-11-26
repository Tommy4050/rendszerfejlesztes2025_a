// routes/postRoutes.js
import { Router } from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  likePost,
  unlikePost,
  addComment,
  getComments,
} from "../controllers/postController.js";

const router = Router();

// Like / unlike
router.post("/:id/like", protect, likePost);
router.post("/:id/unlike", protect, unlikePost);

// Comments
router.post("/:id/comments", protect, addComment);
router.get("/:id/comments", protect, getComments);

export default router;
