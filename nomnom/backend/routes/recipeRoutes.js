import { Router } from "express";
import { createRecipe, getRecipeById, getMyRecipes } from "../controllers/recipeController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = Router();

router.post("/", protect, createRecipe);
router.get("/:id", protect, getRecipeById);
router.get("/", protect, getMyRecipes);

export default router;