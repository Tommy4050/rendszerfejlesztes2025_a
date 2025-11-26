// routes/uploadRoutes.js
import { Router } from "express";
import { protect } from "../middleware/authMiddleware.js";
import { upload } from "../middleware/uploadMiddleware.js";
import { uploadImage } from "../controllers/uploadController.js";

const router = Router();

router.post("/image", protect, upload.single("image"), uploadImage);

export default router;
