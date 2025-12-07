import jwt from "jsonwebtoken";
import User from "../models/User.js";

const getUserIdFromRequest = (req) => {
  const authHeader = req.headers.authorization || "";
  if (!authHeader.startsWith("Bearer ")) return null;

  const token = authHeader.substring(7);

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    return payload.id || payload.userId || payload._id || null;
  } catch (err) {
    console.error("JWT verify error in userController:", err.message);
    return null;
  }
};

export const getMe = async (req, res) => {
  const userId = getUserIdFromRequest(req);
  if (!userId) {
    return res.status(401).json({ message: "Not authorized" });
  }

  try {
    const user = await User.findById(userId).select(
      "username email bio profilePictureRef createdAt"
    );

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({
      id: user._id.toString(),
      username: user.username,
      email: user.email,
      bio: user.bio || "",
      profilePictureUrl: user.profilePictureRef || null,
      createdAt: user.createdAt,
    });
  } catch (err) {
    console.error("getMe error:", err.message);
    res.status(500).json({ message: "Failed to load profile" });
  }
};

export const updateMe = async (req, res) => {
  const userId = getUserIdFromRequest(req);
  if (!userId) {
    return res.status(401).json({ message: "Not authorized" });
  }

  const { bio, profilePictureUrl } = req.body;

  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (typeof bio === "string") {
      user.bio = bio.trim();
    }

    if (
      typeof profilePictureUrl === "string" &&
      profilePictureUrl.trim() !== ""
    ) {
      user.profilePictureRef = profilePictureUrl.trim();
    }

    await user.save();

    res.json({
      id: user._id.toString(),
      username: user.username,
      email: user.email,
      bio: user.bio || "",
      profilePictureUrl: user.profilePictureRef || null,
      createdAt: user.createdAt,
    });
  } catch (err) {
    console.error("updateMe error:", err.message);
    res.status(500).json({ message: "Failed to update profile" });
  }
};

export const getUserById = async (req, res) => {
  const { id } = req.params;

  try {
    const user = await User.findById(id).select(
      "username email bio profilePictureRef createdAt"
    );

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({
      id: user._id.toString(),
      username: user.username,
      email: user.email,
      bio: user.bio || "",
      profilePictureUrl: user.profilePictureRef || null,
      createdAt: user.createdAt,
    });
  } catch (err) {
    console.error("getUserById error:", err.message);
    res.status(500).json({ message: "Failed to load user" });
  }
};

