import axios from "axios";
import Ingredient from "../models/Ingredient.js";

const OPEN_FOOD_FACTS_API = process.env.OPEN_FOOD_FACTS_API || "https://world.openfoodfacts.org/api/v0";

const emptyNutrients = () => ({
  calories: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
  fiber: 0,
});

// Fetch product nutriments from OpenFoodFacts via barcode
const fetchOpenFoodFactsNutrients = async (barcode) => {
  const url = `${OPEN_FOOD_FACTS_API}/product/${barcode}.json`;
  const resp = await axios.get(url);

  if (!resp.data || resp.data.status !== 1) {
    throw new Error("Product not found on OpenFoodFacts");
  }

  const nutriments = resp.data.product?.nutriments || {};

  return {
    calories: nutriments["energy-kcal_100g"] ?? 0,
    protein: nutriments["proteins_100g"] ?? 0,
    carbs: nutriments["carbohydrates_100g"] ?? 0,
    fat: nutriments["fat_100g"] ?? 0,
    fiber: nutriments["fiber_100g"] ?? 0,
  };
};

// Find or create Ingredient in DB based on barcode
const getOrCreateIngredientByBarcode = async ({ name, barcode }) => {
  if (!barcode) return null;

  let ingredient = await Ingredient.findOne({ externalId: barcode });

  if (!ingredient) {
    const nutrientsPerBase = await fetchOpenFoodFactsNutrients(barcode);

    ingredient = await Ingredient.create({
      name,
      externalId: barcode,
      source: "openfoodfacts",
      baseUnit: "g",
      baseAmount: 100, // OFF per 100 g
      nutrientsPerBase,
    });
  }

  return ingredient;
};

// Scale nutrients from baseAmount to the requested quantity
const scaleNutrients = (nutrients, factor) => ({
  calories: (nutrients.calories || 0) * factor,
  protein: (nutrients.protein || 0) * factor,
  carbs: (nutrients.carbs || 0) * factor,
  fat: (nutrients.fat || 0) * factor,
  fiber: (nutrients.fiber || 0) * factor,
});

// Entry point for the controller
// rawIngredients: [{ name, quantity, unit, barcode? }, ...]
export const buildRecipeIngredientsWithNutrition = async (rawIngredients) => {
  if (!Array.isArray(rawIngredients) || rawIngredients.length === 0) {
    return {
      recipeIngredients: [],
      totalNutrients: emptyNutrients(),
    };
  }

  const recipeIngredients = [];
  let total = emptyNutrients();

  for (const raw of rawIngredients) {
    const { name, quantity, unit, barcode } = raw;

    if (!name || !quantity || !unit) {
      // skip invalid lines
      continue;
    }

    let ingredientDoc = null;
    let baseNutrients = emptyNutrients();
    let baseAmount = 100;

    try {
      // If barcode given -> use OFF + Ingredient collection
      if (barcode) {
        ingredientDoc = await getOrCreateIngredientByBarcode({
          name,
          barcode,
        });

        if (ingredientDoc && ingredientDoc.nutrientsPerBase) {
          baseNutrients = ingredientDoc.nutrientsPerBase;
          baseAmount = ingredientDoc.baseAmount || 100;
        }
      }
    } catch (err) {
      console.error(
        `Error fetching nutrition for ingredient "${name}" (barcode: ${barcode})`,
        err.message
      );
    }

    // We assume unit is compatible with baseUnit (e.g. grams)
    const factor = quantity / baseAmount;
    const derived = scaleNutrients(baseNutrients, factor);

    // Sum into total
    total = {
      calories: total.calories + derived.calories,
      protein: total.protein + derived.protein,
      carbs: total.carbs + derived.carbs,
      fat: total.fat + derived.fat,
      fiber: total.fiber + derived.fiber,
    };

    recipeIngredients.push({
      ingredient: ingredientDoc?._id,
      name,
      quantity,
      unit,
      derivedNutrients: derived,
      externalId: barcode,
    });
  }

  return { recipeIngredients, totalNutrients: total };
};
