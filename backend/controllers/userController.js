import bcrypt from "bcryptjs";
import asyncHandler from "express-async-handler";
import User from "../models/User.js";

// Register user
export const registerUser = async (req, res) => {
    try {
        const { username, email, password } = req.body;

        //Validate input
        if(!username || !email || !password) {
            return res.status(400).json({ message: "Please fill in all fields" });
        }

        // User already exist
        const userExists = await User.findOne({ email });
        if(userExists) return res.status(400).json({ message: "User already exist" });

        // Hashing password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Create new user
        const user  = await User.create({ username, email, password: hashedPassword });
        res.status(201).json({ _id: user._id, username: user.username, email: user.email });
    } catch(error) {
        res.status(500).json({ message: error.message });
    }
};

export const loginUser = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    //Mock replace it with DB querry !
    const user  = {
        _id: "mock123",
        name: "Test User",
        email: "test@example.com",
        password: await bcrypt.hash("password123", 10)
    }

    if(user && (await bcrypt.compare(password, user.password))) {
        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            token: "fake-jwt-token", // Generate a real one later
        });
    } else {
        res.status(401);
        throw new Error("Invalid email or password");
    }
});

// Get all users (for testing)
export const getUsers = async (req, res) => {
    try {
        const users = await User.find().select("-password"); // Hides the password field
        res.json(users);
    } catch(error) {
        res.status(500).json({ message: error.message });
    }
};