import { v2 as cloudinary } from "cloudinary";
import dotenv from "dotenv";
import { fileURLToPath } from "url";
import path from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({
  path: path.join(__dirname, "..", ".env"),
});

// Debug logs – check once, then you can delete these lines
console.log("[Cloudinary] CLOUDINARY_CLOUD_NAME =", process.env.CLOUDINARY_CLOUD_NAME);
console.log("[Cloudinary] has API_KEY   =", !!process.env.CLOUDINARY_API_KEY);
console.log("[Cloudinary] has API_SECRET =", !!process.env.CLOUDINARY_API_SECRET);

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export default cloudinary;
