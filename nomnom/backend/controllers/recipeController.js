import Recipe from "../models/Recipe.js";
import Post from "../models/Post.js";
import { buildRecipeIngredientsWithNutrition } from "../services/nutritionService.js";

export const createRecipe = async (req, res) => {
  try {
    const userId = req.user.userId;
    const {
      name,
      description,
      images = [],
      cookTimeMin,
      ingredients = [], // [{ name, quantity, unit, barcode? }, ...]
      steps = [],
      dietaryInfo,
    } = req.body;

    if (!name || !description) {
      return res
        .status(400)
        .json({ message: "name and description are required" });
    }

    // Build recipeIngredients + totalNutrients using OpenFoodFacts (if barcode present)
    const { recipeIngredients, totalNutrients } =
      await buildRecipeIngredientsWithNutrition(ingredients);

    const recipe = await Recipe.create({
      name,
      description,
      images,
      cookTimeMin,
      ingredients: recipeIngredients,
      steps,
      dietaryInfo,
      totalNutrients,
      createdBy: userId,
    });

    // Auto-create a post for the recipe
    const post = await Post.create({
      author: userId,
      recipe: recipe._id,
      content: description.slice(0, 200),
      images,
      type: "RECIPE",
    });

    recipe.post = post._id;
    await recipe.save();

    const populated = await Recipe.findById(recipe._id)
      .populate("createdBy", "username profilePictureRef")
      .populate("post")
      .populate("ingredients.ingredient", "name externalId");

    res.status(201).json({
      message: "Recipe created successfully",
      recipe: populated,
    });
  } catch (err) {
    console.error("createRecipe error:", err);
    res.status(500).json({ message: "Server error creating recipe" });
  }
};

export const getRecipeById = async (req, res) => {
  try {
    const { id } = req.params;

    const recipe = await Recipe.findById(id)
      .populate("createdBy", "username profilePictureRef")
      .populate("post");

    if (!recipe) {
      return res.status(404).json({ message: "Recipe not found" });
    }

    res.json({ recipe });
  } catch (err) {
    console.error("getRecipeById error:", err);
    res.status(500).json({ message: "Server error fetching recipe" });
  }
};

export const getMyRecipes = async (req, res) => {
  try {
    const userId = req.user.userId;

    const recipes = await Recipe.find({ createdBy: userId })
      .sort({ createdAt: -1 })
      .populate("post");

    res.json({ recipes });
  } catch (err) {
    console.error("getMyRecipes error:", err);
    res.status(500).json({ message: "Server error fetching recipes" });
  }
};
