import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../models/User.js";

const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: "7d" });
};

const toSafeUser = (user) => {
  const obj = user.toObject();
  delete obj.passwordHash;
  return obj;
};

export const registerUser = async (req, res) => {
  try {
    const { username, email, password, bio } = req.body;

    if (!username || !email || !password) {
      return res
        .status(400)
        .json({ message: "username, email and password are required" });
    }

    if (password.length < 6) {
      return res
        .status(400)
        .json({ message: "Password must be at least 6 characters" });
    }

    const existing = await User.findOne({
      $or: [{ email }, { username }],
    });
    if (existing) {
      return res
        .status(409)
        .json({ message: "User with this email or username already exists" });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const user = await User.create({
      username,
      email,
      passwordHash,
      bio: bio ?? "",
    });

    const token = generateToken(user._id.toString());

    res.status(201).json({
      message: "User registered successfully",
      token,
      user: toSafeUser(user),
    });
  } catch (err) {
    console.error("registerUser error:", err);
    res.status(500).json({ message: "Server error during registration" });
  }
};

export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({ message: "email and password are required" });
    }

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);

    if (!isMatch) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const token = generateToken(user._id.toString());

    res.json({
      message: "Login successful",
      token,
      user: toSafeUser(user),
    });
  } catch (err) {
    console.error("loginUser error:", err);
    res.status(500).json({ message: "Server error during login" });
  }
};

export const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    res.json({ user: toSafeUser(user) });
  } catch (err) {
    console.error("getMe error:", err);
    res.status(500).json({ message: "Server error fetching current user" });
  }
};
