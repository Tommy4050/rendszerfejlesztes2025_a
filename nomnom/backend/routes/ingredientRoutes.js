import { Router } from "express";
import { protect } from "../middleware/authMiddleware.js";
import { searchIngredients } from "../controllers/ingredientController.js";

const router = Router();

router.get("/search", protect, searchIngredients);

export default router;
