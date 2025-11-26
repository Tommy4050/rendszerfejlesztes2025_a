import Group from "../models/Group.js";
import GroupMember from "../models/GroupMember.js";
import Post from "../models/Post.js";

export const getMyGroups = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Find all group memberships for this user
    const memberships = await GroupMember.find({ user: userId })
      .select("group")
      .lean();

    if (memberships.length === 0) {
      return res.json({ groups: [] });
    }

    const groupIds = memberships.map((m) => m.group);

    // Load the groups themselves
    const groups = await Group.find({ _id: { $in: groupIds } })
      .sort({ createdAt: -1 })
      .lean();

    // Compute member counts for each group
    const counts = await GroupMember.aggregate([
      { $match: { group: { $in: groupIds } } },
      { $group: { _id: "$group", count: { $sum: 1 } } },
    ]);

    const countMap = new Map(
      counts.map((c) => [String(c._id), c.count])
    );

    const payload = groups.map((g) => ({
      _id: g._id,
      id: g._id, // convenience for frontend
      name: g.name,
      description: g.description,
      coverPictureRef: g.coverPictureRef,
      memberCount: countMap.get(String(g._id)) || 0,
      createdAt: g.createdAt,
    }));

    return res.json({ groups: payload });
  } catch (err) {
    console.error("getMyGroups error:", err);
    return res
      .status(500)
      .json({ message: "Server error loading groups" });
  }
};

export const createGroup = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { name, description, coverPictureRef } = req.body;

    if (!name) {
      return res.status(400).json({ message: "Group name is required" });
    }

    const group = await Group.create({
      name,
      description,
      coverPictureRef,
      createdBy: userId,
    });

    // creator becomes admin + member
    await GroupMember.create({
      group: group._id,
      user: userId,
      role: "admin",
    });

    res.status(201).json({
      message: "Group created successfully",
      group,
    });
  } catch (err) {
    console.error("createGroup error:", err);
    res.status(500).json({ message: "Server error creating group" });
  }
};

export const joinGroup = async (req, res) => {
  try {
    const userId = req.user.userId;
    const groupId = req.params.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    await GroupMember.findOneAndUpdate(
      { group: groupId, user: userId },
      { $setOnInsert: { role: "member" } },
      { upsert: true, new: true }
    );

    res.json({ message: "Joined group successfully" });
  } catch (err) {
    console.error("joinGroup error:", err);
    res.status(500).json({ message: "Server error joining group" });
  }
};

export const getGroupPosts = async (req, res) => {
  try {
    const groupId = req.params.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const posts = await Post.find({ group: groupId })
      .sort({ createdAt: -1 })
      .populate("author", "username profilePictureRef")
      .populate("recipe");

    res.json({ group, posts });
  } catch (err) {
    console.error("getGroupPosts error:", err);
    res.status(500).json({ message: "Server error fetching group posts" });
  }
};

export const sharePostToGroup = async (req, res) => {
  try {
    const userId = req.user.userId;
    const groupId = req.params.id;
    const { postId, content } = req.body; // content = optional message with share

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    // must be member to share
    const membership = await GroupMember.findOne({
      group: groupId,
      user: userId,
    });

    if (!membership) {
      return res
        .status(403)
        .json({ message: "You must join the group to share posts" });
    }

    const originalPost = await Post.findById(postId).populate(
      "author",
      "username"
    );
    if (!originalPost) {
      return res.status(404).json({ message: "Original post not found" });
    }

    const sharedPost = await Post.create({
      author: userId,
      group: groupId,
      recipe: originalPost.recipe,
      type: "SHARE",
      sharedFrom: originalPost._id,
      content: content || "",
      images: originalPost.images,
    });

    const populated = await Post.findById(sharedPost._id)
      .populate("author", "username profilePictureRef")
      .populate("recipe")
      .populate("sharedFrom")
      .populate("group", "name");

    res.status(201).json({
      message: "Post shared to group",
      post: populated,
    });
  } catch (err) {
    console.error("sharePostToGroup error:", err);
    res.status(500).json({ message: "Server error sharing post to group" });
  }
};
