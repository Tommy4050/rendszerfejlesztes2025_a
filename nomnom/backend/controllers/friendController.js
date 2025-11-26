import Friend from "../models/Friend.js";
import User from "../models/User.js";

export const followUser = async (req, res) => {
  try {
    const userId = req.user.userId;
    const targetId = req.params.id;

    if (userId === targetId) {
      return res.status(400).json({ message: "You cannot follow yourself" });
    }

    const targetUser = await User.findById(targetId);
    if (!targetUser) {
      return res.status(404).json({ message: "User to follow not found" });
    }

    await Friend.findOneAndUpdate(
      { user: userId, friend: targetId },
      { status: "following" },
      { upsert: true, new: true }
    );

    res.json({ message: "Now following user" });
  } catch (err) {
    console.error("followUser error:", err);
    res.status(500).json({ message: "Server error following user" });
  }
};

export const unfollowUser = async (req, res) => {
  try {
    const userId = req.user.userId;
    const targetId = req.params.id;

    await Friend.findOneAndDelete({ user: userId, friend: targetId });

    res.json({ message: "Unfollowed user" });
  } catch (err) {
    console.error("unfollowUser error:", err);
    res.status(500).json({ message: "Server error unfollowing user" });
  }
};

export const listFollowing = async (req, res) => {
  try {
    const userId = req.user.userId;

    const following = await Friend.find({ user: userId })
      .populate("friend", "username profilePictureRef")
      .sort({ createdAt: -1 });

    res.json({
      count: following.length,
      users: following.map((f) => f.friend),
    });
  } catch (err) {
    console.error("listFollowing error:", err);
    res.status(500).json({ message: "Server error listing following" });
  }
};

export const listFollowers = async (req, res) => {
  try {
    const userId = req.user.userId;

    const followers = await Friend.find({ friend: userId })
      .populate("user", "username profilePictureRef")
      .sort({ createdAt: -1 });

    res.json({
      count: followers.length,
      users: followers.map((f) => f.user),
    });
  } catch (err) {
    console.error("listFollowers error:", err);
    res.status(500).json({ message: "Server error listing followers" });
  }
};
