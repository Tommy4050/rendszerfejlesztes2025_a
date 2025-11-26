// controllers/postController.js
import Post from "../models/Post.js";
import PostLike from "../models/PostLike.js";
import Comment from "../models/Comment.js";

export const likePost = async (req, res) => {
  try {
    const userId = req.user.userId;
    const postId = req.params.id;

    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    // upsert like
    const existingLike = await PostLike.findOne({ post: postId, user: userId });

    if (existingLike) {
      // already liked, do nothing
      return res.json({ message: "Post already liked" });
    }

    await PostLike.create({ post: postId, user: userId });

    post.likeCount = (post.likeCount || 0) + 1;
    await post.save();

    res.json({ message: "Post liked", likeCount: post.likeCount });
  } catch (err) {
    console.error("likePost error:", err);
    res.status(500).json({ message: "Server error liking post" });
  }
};

export const unlikePost = async (req, res) => {
  try {
    const userId = req.user.userId;
    const postId = req.params.id;

    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    const like = await PostLike.findOneAndDelete({ post: postId, user: userId });

    if (!like) {
      return res.json({ message: "Post was not liked" });
    }

    post.likeCount = Math.max((post.likeCount || 0) - 1, 0);
    await post.save();

    res.json({ message: "Post unliked", likeCount: post.likeCount });
  } catch (err) {
    console.error("unlikePost error:", err);
    res.status(500).json({ message: "Server error unliking post" });
  }
};

export const addComment = async (req, res) => {
  try {
    const userId = req.user.userId;
    const postId = req.params.id;
    const { content } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ message: "Comment content is required" });
    }

    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    const comment = await Comment.create({
      post: postId,
      author: userId,
      content: content.trim(),
    });

    post.commentCount = (post.commentCount || 0) + 1;
    await post.save();

    const populated = await Comment.findById(comment._id).populate(
      "author",
      "username profilePictureRef"
    );

    res.status(201).json({
      message: "Comment added",
      comment: populated,
      commentCount: post.commentCount,
    });
  } catch (err) {
    console.error("addComment error:", err);
    res.status(500).json({ message: "Server error adding comment" });
  }
};

export const getComments = async (req, res) => {
  try {
    const postId = req.params.id;

    const post = await Post.findById(postId).select("_id");
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    const comments = await Comment.find({ post: postId })
      .sort({ createdAt: 1 })
      .populate("author", "username profilePictureRef");

    res.json({ comments });
  } catch (err) {
    console.error("getComments error:", err);
    res.status(500).json({ message: "Server error fetching comments" });
  }
};
