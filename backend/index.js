import express from "express";
import dotenv from "dotenv";
import connectDB from "./config/db.js";
import userRoutes from "./routes/userRoutes.js";
import errorHandler from "./middleware/errorMiddleware.js";

console.log("🚀 Backend file started running...");


dotenv.config();
connectDB();

const app = express();
app.use(express.json());

// Routes
app.use("/api/users", userRoutes);

// Test
app.get("/", (req, res) => {
  res.send("NomNom backend is running 🚀");
});

//Error handling
app.use(errorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));