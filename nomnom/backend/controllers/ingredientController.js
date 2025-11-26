import { searchIngredientsByName } from "../services/ingredientSearchService.js";

export const searchIngredients = async (req, res) => {
  try {
    const q = req.query.q || req.query.query || "";
    const results = await searchIngredientsByName(q.toString());

    res.json({ products: results });
  } catch (err) {
    console.error("searchIngredients error:", err);
    res
      .status(500)
      .json({ message: "Server error searching ingredients" });
  }
};
