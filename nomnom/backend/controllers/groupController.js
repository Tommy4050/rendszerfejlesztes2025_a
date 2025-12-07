import Group from "../models/Group.js";
import GroupMember from "../models/GroupMember.js";
import Post from "../models/Post.js";

const isGroupAdmin = async (groupId, userId) => {
  if (!userId) return false;
  const admin = await GroupMember.exists({
    group: groupId,
    user: userId,
    role: "admin",
  });
  return !!admin;
};

export const getMyGroups = async (req, res) => {
  try {
    const userId = req.user.userId;

    const memberships = await GroupMember.find({ user: userId })
      .select("group role")
      .lean();

    if (memberships.length === 0) {
      return res.json({ groups: [] });
    }

    const groupIds = memberships.map((m) => m.group);
    const membershipMap = new Map(
      memberships.map((m) => [String(m.group), m.role])
    );

    const groups = await Group.find({ _id: { $in: groupIds } })
      .sort({ createdAt: -1 })
      .lean();

    const counts = await GroupMember.aggregate([
      { $match: { group: { $in: groupIds } } },
      { $group: { _id: "$group", count: { $sum: 1 } } },
    ]);

    const countMap = new Map(
      counts.map((c) => [String(c._id), c.count])
    );

    const payload = groups.map((g) => {
      const idStr = String(g._id);
      const memberCount = countMap.get(idStr) || 0;
      const role = membershipMap.get(idStr);
      const isAdmin = role === "admin";

      return {
        _id: g._id,
        id: g._id,
        name: g.name,
        description: g.description,
        coverPictureRef: g.coverPictureRef,
        memberCount,
        createdAt: g.createdAt,
        isMember: true,
        isAdmin,
      };
    });

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

    await GroupMember.create({
      group: group._id,
      user: userId,
      role: "admin",
    });

    const memberCount = await GroupMember.countDocuments({
      group: group._id,
    });

    res.status(201).json({
      message: "Group created successfully",
      group: {
        ...group.toObject(),
        id: group._id,
        memberCount,
        isMember: true,
        isAdmin: true,
      },
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

    let membership = await GroupMember.findOne({
      group: groupId,
      user: userId,
    });

    if (!membership) {
      membership = await GroupMember.create({
        group: groupId,
        user: userId,
        role: "member",
      });
    }

    const memberCount = await GroupMember.countDocuments({ group: groupId });
    const isAdmin = membership.role === "admin";

    const payload = {
      ...group.toObject(),
      id: group._id,
      memberCount,
      isMember: true,
      isAdmin,
    };

    res.json({
      message: "Joined group successfully",
      group: payload,
      memberCount,
      isMember: true,
      isAdmin,
    });
  } catch (err) {
    console.error("joinGroup error:", err);
    res.status(500).json({ message: "Server error joining group" });
  }
};

export const getGroupPosts = async (req, res) => {
  try {
    const userId = req.user.userId;
    const groupId = req.params.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const posts = await Post.find({ group: groupId })
      .sort({ createdAt: -1 })
      .populate("author", "username profilePictureRef")
      .populate("recipe");

    const memberCount = await GroupMember.countDocuments({ group: groupId });
    const membership = await GroupMember.findOne({
      group: groupId,
      user: userId,
    }).select("role");
    const isMember = !!membership;
    const isAdmin = membership?.role === "admin";

    const payload = {
      ...group.toObject(),
      id: group._id,
      memberCount,
      isMember,
      isAdmin,
    };

    res.json({ group: payload, posts });
  } catch (err) {
    console.error("getGroupPosts error:", err);
    res.status(500).json({ message: "Server error fetching group posts" });
  }
};

export const sharePostToGroup = async (req, res) => {
  try {
    const userId = req.user.userId;
    const groupId = req.params.id;
    const { postId, content } = req.body;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

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

export const getGroupMembers = async (req, res) => {
  try {
    const userId = req.user.userId;
    const groupId = req.params.id;

    const group = await Group.findById(groupId).select("createdBy");
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const memberships = await GroupMember.find({ group: groupId })
      .populate("user", "username profilePictureRef")
      .lean();

    const members = memberships.map((m) => ({
      id: m._id,
      role: m.role,
      user: m.user,
    }));

    const isAdmin = await isGroupAdmin(groupId, userId);
    const isOwner =
      group.createdBy &&
      group.createdBy.toString() === userId;

    res.json({
      members,
      isAdmin,
      isOwner,
    });
  } catch (err) {
    console.error("getGroupMembers error:", err);
    res.status(500).json({ message: "Server error fetching members" });
  }
};

export const updateGroup = async (req, res) => {
  try {
    const userId = req.user.userId;
    const groupId = req.params.id;
    const { name, description, coverPictureRef } = req.body;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const ownerId = group.createdBy?.toString();
    const admin = await isGroupAdmin(groupId, userId);
    if (!admin && userId !== ownerId) {
      return res
        .status(403)
        .json({ message: "Only admins can edit the group" });
    }

    if (name && name.trim()) group.name = name.trim();
    if (description !== undefined) group.description = description;
    if (coverPictureRef !== undefined) group.coverPictureRef =
      coverPictureRef;

    await group.save();

    const memberCount = await GroupMember.countDocuments({ group: groupId });
    const isAdmin = await isGroupAdmin(groupId, userId);

    res.json({
      message: "Group updated",
      group: {
        ...group.toObject(),
        id: group._id,
        memberCount,
        isMember: true,
        isAdmin,
      },
    });
  } catch (err) {
    console.error("updateGroup error:", err);
    res.status(500).json({ message: "Server error updating group" });
  }
};

export const updateGroupMemberRole = async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const groupId = req.params.id;
    const targetUserId = req.params.userId;
    const { role } = req.body;

    if (!["member", "admin"].includes(role)) {
      return res.status(400).json({ message: "Invalid role" });
    }

    const group = await Group.findById(groupId).select("createdBy");
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const ownerId = group.createdBy?.toString();
    const currentIsAdmin = await isGroupAdmin(groupId, currentUserId);

    if (!currentIsAdmin && currentUserId !== ownerId) {
      return res
        .status(403)
        .json({ message: "Only admins can manage roles" });
    }

    const membership = await GroupMember.findOne({
      group: groupId,
      user: targetUserId,
    }).populate("user", "username profilePictureRef");

    if (!membership) {
      return res.status(404).json({ message: "Member not found" });
    }

    if (targetUserId === ownerId) {
      return res
        .status(403)
        .json({ message: "Cannot change the group creator's role" });
    }

    if (membership.role === "admin" && role === "member") {
      if (currentUserId !== ownerId) {
        return res.status(403).json({
          message: "Only the group creator can remove admin role",
        });
      }
    }

    membership.role = role;
    await membership.save();

    res.json({
      message: "Role updated",
      member: {
        id: membership._id,
        role: membership.role,
        user: membership.user,
      },
    });
  } catch (err) {
    console.error("updateGroupMemberRole error:", err);
    res.status(500).json({ message: "Server error updating member role" });
  }
};

export const removeGroupMember = async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const groupId = req.params.id;
    const targetUserId = req.params.userId;

    const group = await Group.findById(groupId).select("createdBy");
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const ownerId = group.createdBy?.toString();
    const currentIsAdmin = await isGroupAdmin(groupId, currentUserId);

    if (!currentIsAdmin && currentUserId !== ownerId) {
      return res
        .status(403)
        .json({ message: "Only admins can remove members" });
    }

    const membership = await GroupMember.findOne({
      group: groupId,
      user: targetUserId,
    });

    if (!membership) {
      return res.status(404).json({ message: "Member not found" });
    }

    if (targetUserId === ownerId) {
      return res
        .status(403)
        .json({ message: "Cannot remove the group creator" });
    }

    if (membership.role === "admin" && currentUserId !== ownerId) {
      return res.status(403).json({
        message: "Only the group creator can remove an admin from the group",
      });
    }

    await GroupMember.deleteOne({
      group: groupId,
      user: targetUserId,
    });

    const memberCount = await GroupMember.countDocuments({ group: groupId });

    res.json({
      message: "Member removed",
      memberCount,
    });
  } catch (err) {
    console.error("removeGroupMember error:", err);
    res.status(500).json({ message: "Server error removing member" });
  }
};

export const deleteGroupPost = async (req, res) => {
  try {
    const userId = req.user.userId;
    const groupId = req.params.id;
    const postId = req.params.postId;

    const isAdmin = await isGroupAdmin(groupId, userId);
    const group = await Group.findById(groupId).select("createdBy");
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }
    const ownerId = group.createdBy?.toString();

    if (!isAdmin && userId !== ownerId) {
      return res
        .status(403)
        .json({ message: "Only admins can delete posts" });
    }

    const post = await Post.findOneAndDelete({
      _id: postId,
      group: groupId,
    });

    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    res.json({ message: "Post deleted" });
  } catch (err) {
    console.error("deleteGroupPost error:", err);
    res.status(500).json({ message: "Server error deleting post" });
  }
};
