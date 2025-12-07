import { Router } from "express";
import { createGroup, joinGroup, getGroupPosts, sharePostToGroup, getMyGroups, getGroupMembers, updateGroup, updateGroupMemberRole, removeGroupMember, deleteGroupPost } from "../controllers/groupController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = Router();

router.get("/", protect, getMyGroups);
router.post("/", protect, createGroup);
router.post("/:id/join", protect, joinGroup);

router.patch("/:id", protect, updateGroup);
router.get("/:id/members", protect, getGroupMembers);
router.patch("/:id/members/:userId", protect, updateGroupMemberRole);
router.delete("/:id/members/:userId", protect, removeGroupMember);
router.delete("/:id/posts/:postId", protect, deleteGroupPost);

router.get("/:id/posts", protect, getGroupPosts);
router.post("/:id/share", protect, sharePostToGroup);

export default router;
