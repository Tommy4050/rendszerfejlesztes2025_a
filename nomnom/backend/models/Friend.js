import mongoose from "mongoose";

const { Schema } = mongoose;

const friendSchema = new Schema(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true, // follower
    },
    friend: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true, // followed user
    },
    status: {
      type: String,
      enum: ["following"],
      default: "following",
    },
  },
  {
    timestamps: true,
  }
);

// a user can follow another only once
friendSchema.index({ user: 1, friend: 1 }, { unique: true });

const Friend = mongoose.model("Friend", friendSchema);
export default Friend;
