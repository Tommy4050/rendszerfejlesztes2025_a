import mongoose from "mongoose";

const { Schema } = mongoose;

const userSchema = new Schema(
  {
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      minlength: 3,
      maxlength: 50,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: {
      type: String,
      required: true,
    },
    profilePictureRef: {
      type: String, // Cloudinary
    },
    bio: {
      type: String,
      maxlength: 300,
    },
    preferences: {
      type: Map, // e.g. { vegetarian: true, glutenFree: false }
      of: Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true, // createdAt, updatedAt
  }
);

const User = mongoose.model("User", userSchema);
export default User;
