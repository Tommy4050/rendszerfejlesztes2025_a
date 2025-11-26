import mongoose from "mongoose";

const { Schema } = mongoose;

const postSchema = new Schema(
  {
    author: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    recipe: {
      type: Schema.Types.ObjectId,
      ref: "Recipe",
    },
    group: {
      type: Schema.Types.ObjectId,
      ref: "Group",
    },
    content: {
      type: String,
      default: "",
    },
    images: {
      type: [String],
      default: [],
    },
    type: {
      type: String,
      enum: ["RECIPE", "SHARE", "TEXT"],
      default: "RECIPE",
    },
    sharedFrom: {
      type: Schema.Types.ObjectId,
      ref: "Post",
    },
    likeCount: {
      type: Number,
      default: 0,
    },
    commentCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

const Post = mongoose.model("Post", postSchema);
export default Post;
