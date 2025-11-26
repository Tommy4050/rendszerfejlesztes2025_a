import cloudinary from "../config/cloudinary.js";

export const uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }

    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: "nomnom",
        resource_type: "image",
      },
      (error, result) => {
        if (error) {
          console.error("Cloudinary upload error:", error);
          return res
            .status(500)
            .json({ message: "Error uploading image", error: error.message });
        }

        return res.status(201).json({
          message: "Image uploaded successfully",
          url: result.secure_url,
          public_id: result.public_id,
        });
      }
    );

    uploadStream.end(req.file.buffer);
  } catch (err) {
    console.error("uploadImage error:", err);
    res.status(500).json({ message: "Server error uploading image" });
  }
};
