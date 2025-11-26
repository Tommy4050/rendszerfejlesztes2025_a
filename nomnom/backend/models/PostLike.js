import mongoose from "mongoose";

const { Schema } = mongoose;

const postLikeSchema = new Schema(
  {
    post: {
      type: Schema.Types.ObjectId,
      ref: "Post",
      required: true,
    },
    user: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// one like per user per post
postLikeSchema.index({ post: 1, user: 1 }, { unique: true });

const PostLike = mongoose.model("PostLike", postLikeSchema);
export default PostLike;
