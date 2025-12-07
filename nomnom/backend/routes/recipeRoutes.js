import { Router } from "express";
import { createRecipe, getRecipeById, getMyRecipes, getUserRecipes } from "../controllers/recipeController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = Router();

router.post("/", protect, createRecipe);

router.get("/", protect, getMyRecipes);
router.get("/user/:userId", protect, getUserRecipes);

router.get("/:id", protect, getRecipeById);

export default router;
