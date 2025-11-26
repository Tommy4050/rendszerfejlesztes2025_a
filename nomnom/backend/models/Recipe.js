import mongoose from "mongoose";

const { Schema } = mongoose;

const nutrientsSchema = new Schema(
  {
    calories: { type: Number, default: 0 },
    protein: { type: Number, default: 0 },
    carbs: { type: Number, default: 0 },
    fat: { type: Number, default: 0 },
    fiber: { type: Number, default: 0 },
  },
  { _id: false }
);

const dietaryInfoSchema = new Schema(
  {
    vegan: { type: Boolean, default: false },
    vegetarian: { type: Boolean, default: false },
    glutenFree: { type: Boolean, default: false },
    dairyFree: { type: Boolean, default: false },
    nutFree: { type: Boolean, default: false },
  },
  { _id: false }
);

const recipeIngredientSchema = new Schema(
  {
    ingredient: {
      type: Schema.Types.ObjectId,
      ref: "Ingredient", // optional nice to have
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },

    quantity: {
      type: Number,
      required: true,
    },

    unit: {
      type: String,
      required: true, // "g", "ml", "pcs", etc.
    },

    // nutrients for THIS quantity of this ingredient
    derivedNutrients: {
      type: nutrientsSchema,
      default: () => ({}),
    },

    // optional: barcode sent from client when creating
    externalId: {
      type: String,
    },
  },
  { _id: false }
);

const recipeSchema = new Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
    },
    images: {
      type: [String], // URLs
      default: [],
    },
    cookTimeMin: {
      type: Number,
      default: 0,
    },

    ingredients: {
      type: [recipeIngredientSchema],
      default: [],
    },

    steps: {
      type: [String],
      default: [],
    },

    // sum of all derivedNutrients from ingredients
    totalNutrients: {
      type: nutrientsSchema,
      default: () => ({}),
    },

    dietaryInfo: {
      type: dietaryInfoSchema,
      default: () => ({}),
    },

    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    post: {
      type: Schema.Types.ObjectId,
      ref: "Post", // Post automatically created when recipe is created
    },
  },
  {
    timestamps: true,
  }
);

const Recipe = mongoose.model("Recipe", recipeSchema);
export default Recipe;
