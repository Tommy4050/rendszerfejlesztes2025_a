import mongoose from "mongoose";

const connectDB = async () => {
  const {
    MONGO_USER,
    MONGO_PASS,
    MONGO_HOST,
    MONGO_DB,
    MONGO_URI,
  } = process.env;

  let uri = MONGO_URI;

  if (!uri && MONGO_USER && MONGO_PASS && MONGO_HOST && MONGO_DB) {
    const user = encodeURIComponent(MONGO_USER);
    const pass = encodeURIComponent(MONGO_PASS);

    uri = `mongodb+srv://${user}:${pass}@${MONGO_HOST}/${MONGO_DB}?retryWrites=true&w=majority&appName=NomNom`;
  }

  if (!uri) {
    throw new Error(
      "MongoDB connection not configured. Set MONGO_URI or (MONGO_USER, MONGO_PASS, MONGO_HOST, MONGO_DB) in .env"
    );
  }

  try {
    await mongoose.connect(uri);
    console.log("Connected to MongoDB");
  } catch (err) {
    console.error("MongoDB connection error:", err.message);
    throw err;
  }
};

export default connectDB;