import express from "express";
import { getMe, updateMe, getUserById } from "../controllers/userController.js";

const router = express.Router();

router.get("/me", getMe);
router.patch("/me", updateMe);
router.get("/:id", getUserById);

export default router;
