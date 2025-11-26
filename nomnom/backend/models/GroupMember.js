import mongoose from "mongoose";

const { Schema } = mongoose;

const groupMemberSchema = new Schema(
  {
    group: {
      type: Schema.Types.ObjectId,
      ref: "Group",
      required: true,
    },
    user: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    role: {
      type: String,
      enum: ["member", "admin"],
      default: "member",
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

groupMemberSchema.index({ group: 1, user: 1 }, { unique: true });

const GroupMember = mongoose.model("GroupMember", groupMemberSchema);
export default GroupMember;
