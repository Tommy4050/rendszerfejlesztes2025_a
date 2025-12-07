import mongoose from "mongoose";

const { Schema } = mongoose;

const nutrientsPerBaseSchema = new Schema(
  {
    calories: { type: Number, default: 0 },
    protein: { type: Number, default: 0 },
    carbs: { type: Number, default: 0 },
    fat: { type: Number, default: 0 },
    fiber: { type: Number, default: 0 },
  },
  { _id: false }
);

const ingredientSchema = new Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    // e.g. OpenFoodFacts barcode like "737628064502"
    externalId: {
      type: String,
      index: true,
    },

    source: {
      type: String,
      default: "openfoodfacts",
    },

    // nutrition data is defined (usually per 100g)
    baseUnit: {
      type: String,
      default: "g",
    },
    baseAmount: {
      type: Number,
      default: 100, // per 100 g
    },

    nutrientsPerBase: {
      type: nutrientsPerBaseSchema,
      default: () => ({}),
    },
  },
  {
    timestamps: true,
  }
);

ingredientSchema.index({ name: 1 });

const Ingredient = mongoose.model("Ingredient", ingredientSchema);
export default Ingredient;
