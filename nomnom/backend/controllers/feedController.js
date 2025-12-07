import Post from "../models/Post.js";
import Friend from "../models/Friend.js";
import GroupMember from "../models/GroupMember.js";

export const getFeed = async (req, res) => {
  try {
    const userId = req.user.userId;

    const follows = await Friend.find({ user: userId }).select("friend");
    const followingIds = follows.map((f) => f.friend.toString());

    const memberships = await GroupMember.find({ user: userId }).select(
      "group"
    );
    const groupIds = memberships.map((m) => m.group.toString());

    const authorIds = [userId, ...followingIds];

    const query = {
      $or: [{ author: { $in: authorIds } }, { group: { $in: groupIds } }],
    };

    const posts = await Post.find(query)
      .sort({ createdAt: -1 })
      .limit(50)
      .populate("author", "username profilePictureRef")
      .populate("recipe")
      .populate("group", "name");

    res.json({ posts });
  } catch (err) {
    console.error("getFeed error:", err);
    res.status(500).json({ message: "Server error fetching feed" });
  }
};

export const getDiscoverFeed = async (req, res) => {
  try {
    const posts = await Post.find({})
      .sort({ createdAt: -1 })
      .limit(50)
      .populate("author", "username profilePictureRef")
      .populate("recipe")
      .populate("group", "name");

    res.json({ posts });
  } catch (err) {
    console.error("getDiscoverFeed error:", err);
    res
      .status(500)
      .json({ message: "Server error fetching discover feed" });
  }
};
