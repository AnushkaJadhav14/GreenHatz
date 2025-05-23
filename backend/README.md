# AHFLbackend
config/
    db.js
    email.js
models/
    ideaModel.js
    userModel.js
routes/
    formRoutes.js
    ideaRoutes.js
    otpRoutes.js
uploads/
server.js




db.js:
const mongoose = require("mongoose");
require("dotenv").config();

// OTP Database
const otpDb = mongoose.createConnection(process.env.OTP_MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});
otpDb.on("connected", () => console.log("✅ OTP Database Connected"));
otpDb.on("error", (err) => console.error("❌ OTP DB Connection Error:", err));

// Forms Database
const formDb = mongoose.createConnection(process.env.FORM_MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});
formDb.on("connected", () => console.log("✅ Forms Database Connected"));
formDb.on("error", (err) => console.error("❌ Forms DB Connection Error:", err));

// Ideas Database (Main MongoDB)
const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017/Forms";
mongoose
  .connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("✅ MongoDB Connected"))
  .catch((err) => console.error("❌ MongoDB Connection Error:", err));

module.exports = { otpDb, formDb };


email.js:
const nodemailer = require("nodemailer");
require("dotenv").config();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

module.exports = transporter;


ideaModel.js:
const mongoose = require("mongoose");

// -------------------------
// Counter Schema & Model
// -------------------------
const CounterSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  seq: { type: Number, default: 1000 } // Starting value at 1000
});

const Counter = mongoose.model("Counter", CounterSchema);

// -------------------------
// Idea Submission Schema
// -------------------------
const ideaSchema = new mongoose.Schema(
  {
    // Add the auto-generated ideaId field at the top
    ideaId: { type: Number, unique: true },
    employeeName: String,
    employeeId: String,
    employeeFunction: String,
    location: String,
    ideaTheme: String,
    department: String,
    benefitsCategory: String,
    ideaDescription: String,
    impactedProcess: String,
    expectedBenefitsValue: String,
    status: {
      type: String,
      default: "Pending",
      enum: ["Pending", "Approved", "Rejected"]
    },
    attachments: { type: [String], default: [] },
    submissionDate: {
      type: Date,
      default: () =>
        new Date(new Date().getTime() + 5.5 * 60 * 60 * 1000) // Converts UTC to IST
    },
    rejectionReason: { type: String, default: "" },
    rejectedAt: { type: Date, default: null },
    recommendedAt: { type: Date, default: null },
    approvedAt: { type: Date, default: null },
    adminL1Message: { type: String, default: "" }
  },
  { collection: "idea_submissions" }
);

// -------------------------
// Pre-save Hook for ideaId
// -------------------------
ideaSchema.pre("save", async function (next) {
  if (this.isNew) {
    try {
      // Find the counter document for ideaId
      let counter = await Counter.findById("ideaId");
      if (!counter) {
        // If not found, create a new counter document starting at 1000
        counter = await Counter.create({ _id: "ideaId", seq: 1000 });
      }
      // Assign the current sequence value to ideaId
      this.ideaId = counter.seq;
      // Increment the counter for the next document
      counter.seq += 1;
      await counter.save();
      next();
    } catch (error) {
      next(error);
    }
  } else {
    next();
  }
});

const Idea = mongoose.model("Idea", ideaSchema);

module.exports = { Idea };



userModel.js:
const mongoose = require("mongoose");
const { otpDb } = require("../config/db");

const UserSchema = new mongoose.Schema({
  corporateId: String,
  email: String,
  role: String,
  otp: String,
  otpExpiry: Date,
  employeeName: String,
  employeeFunction: String,
  location: String,  
});

// Models
const User = otpDb.model("user_credentials", UserSchema);
const Admin = otpDb.model("admin_credentials", UserSchema);

module.exports = { User, Admin };



formRoute.js:
const express = require("express");
const multer = require("multer");
const { Idea } = require("../models/ideaModel");
const { User } = require("../models/userModel"); // Import the User model
const transporter = require("../config/email");

const router = express.Router();

// File Upload Setup
const storage = multer.diskStorage({
  destination: "./uploads/",
  filename: (req, file, cb) => {
    if (!req.body.employeeId) return cb(new Error("Missing employeeId"));
    const sanitizedFilename = file.originalname.replace(/\s+/g, "_");
    cb(null, `${req.body.employeeId}_${sanitizedFilename}`);
  },
});
const upload = multer({ storage });

// Submit Form
router.post("/submit-form", upload.array("attachments", 10), async (req, res) => {
  try {
    if (!req.body.employeeId) {
      return res.status(400).json({ message: "❌ Employee ID is required" });
    }

    const newIdea = new Idea({
      ...req.body,
      attachments: req.files && req.files.length > 0 ? req.files.map(file => file.filename) : [],
    });

    // After saving newIdea
await newIdea.save();

// Look up the user's email and name from the User collection using the employeeId.
const user = await User.findOne({ corporateId: req.body.employeeId }).lean();
if (user && user.email) {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: user.email,
    subject: "Thank You for Submitting Your Idea!",
    text: `Dear ${user.employeeName},\n\nThank you for submitting your idea through the "Green HatZ" initiative.\n\nWe have received your idea with id "${newIdea.ideaId}" titled "${newIdea.ideaTheme}", and it is currently under review. Our committee will respond shortly.\n\nBest regards,\nAadhar Housing Finance Team`
  };

  try {
    await transporter.sendMail(mailOptions);
  } catch (mailError) {
    console.error("❌ Email sending error:", mailError);
  }
} else {
  console.warn("User not found or email not available for employeeId:", req.body.employeeId);
}


    res.status(201).json({ message: "✅ Form Submitted Successfully!" });
  } catch (error) {
    console.error("❌ Error:", error);
    res.status(500).json({ message: "❌ Error submitting form", error: error.message });
  }
});

// Get all Submissions
router.get("/submissions", async (req, res) => {
  try {
    const ideas = await Idea.find();
    res.status(200).json(ideas);
  } catch (error) {
    res.status(500).json({ message: "❌ Error fetching submissions", error: error.message });
  }
});



//  =========================

// User Dashboard Routes

// 1. Get all ideas (excluding rejected ones)
router.get("/ideas", async (req, res) => {
  try {
    const ideas = await Idea.find({ status: { $ne: "Rejected" } }).select("-__v");
    res.status(200).json(ideas);
  } catch (error) {
    console.error("Error fetching ideas:", error);
    res.status(500).json({ error: "Failed to fetch ideas" });
  }
});

// 2. Get idea details by ID
router.get("/idea/:id", async (req, res) => {
  try {
    const idea = await Idea.findById(req.params.id).select("-__v");
    if (!idea) return res.status(404).json({ error: "Idea not found" });
    res.status(200).json(idea);
  } catch (error) {
    console.error("Error fetching idea details:", error);
    res.status(500).json({ error: "Error fetching idea details" });
  }
});

// 3. Get total, approved, and rejected ideas for a specific employee
router.get("/user-ideas/:employeeId", async (req, res) => {
  try {
    const { employeeId } = req.params;
    if (!employeeId) return res.status(400).json({ error: "Employee ID is required" });

    const ideas = await Idea.find({ employeeId }).select("-__v");

    const approvedCount = ideas.filter((idea) => idea.status === "Approved").length;
    const rejectedCount = ideas.filter((idea) => idea.status === "Rejected").length;

    res.status(200).json({
      totalIdeas: ideas.length,
      approvedCount,
      rejectedCount,
      ideas,
    });
  } catch (error) {
    console.error("Error fetching user ideas:", error);
    res.status(500).json({ error: "Error fetching user ideas" });
  }
});

// 4. Update idea status (Approve or Reject)
router.put("/update-status/:id", async (req, res) => {
  try {
    const { status, rejectionReason } = req.body;

    // Allow only "Approved" or "Rejected" statuses
    if (!["Approved", "Rejected"].includes(status)) {
      return res.status(400).json({ error: "Invalid status value" });
    }

    const updateData = { status };
    if (status === "Rejected" && rejectionReason) {
      updateData.rejectionReason = rejectionReason;
    }

    const updatedIdea = await Idea.findByIdAndUpdate(req.params.id, updateData, { new: true }).select("-__v");

    if (!updatedIdea) return res.status(404).json({ error: "Idea not found" });

    res.status(200).json({ message: "Idea status updated", idea: updatedIdea });
  } catch (error) {
    console.error("Error updating idea status:", error);
    res.status(500).json({ error: "Error updating status" });
  }
});

module.exports = router;



ideaRoute.js:
const express = require("express");
const { Idea } = require("../models/ideaModel");
const { User } = require("../models/userModel");
const { Admin } = require("../models/userModel");
const transporter = require("../config/email");
const { ObjectId } = require("mongoose").Types;

const router = express.Router();

// Get all ideas
router.get("/ideas", async (req, res) => {
  try {
    const ideas = await Idea.find();
    res.json(ideas);
  } catch (error) {
    console.error("Error fetching ideas:", error);
    res.status(500).json({ error: "Error fetching ideas" });
  }
});

// Get idea details by ID
router.get("/idea/:id", async (req, res) => {
  try {
    const ideaId = req.params.id;
    if (!ObjectId.isValid(ideaId)) {
      return res.status(400).json({ error: "Invalid Idea ID format" });
    }
    const idea = await Idea.findById(ideaId);
    if (!idea) return res.status(404).json({ error: "Idea not found" });
    res.json(idea);
  } catch (error) {
    console.error("Error fetching idea details:", error);
    res.status(500).json({ error: "Error fetching idea details" });
  }
});

// Get all rejected ideas
router.get("/rejected-ideas", async (req, res) => {
  try {
    const rejectedIdeas = await Idea.find({ status: "Rejected" });
    res.json(rejectedIdeas);
  } catch (error) {
    console.error("Error fetching rejected ideas:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Get all ideas that are not rejected or approved/recommended to L2
router.get("/ideas", async (req, res) => {
  try {
    const ideas = await Idea.find({ 
      status: { $nin: ["Rejected", "Approved and Recommended to L2"] }
    });
    res.json(ideas);
  } catch (error) {
    console.error("Error fetching ideas:", error);
    res.status(500).json({ error: "Error fetching ideas" });
  }
});


// Update idea status (Approve / Recommend to L2)
router.put("/update-status/:id", async (req, res) => {
  try {
    const { status } = req.body;
    const ideaId = req.params.id;

    if (!ObjectId.isValid(ideaId)) {
      return res.status(400).json({ error: "Invalid Idea ID format" });
    }

    const updatedIdea = await Idea.findByIdAndUpdate(
      ideaId,
      { status },
      { new: true }
    );

    if (!updatedIdea) {
      return res.status(404).json({ error: "Idea not found" });
    }

    res.json({ message: "Idea status updated", idea: updatedIdea });
  } catch (error) {
    console.error("Error updating idea status:", error);
    res.status(500).json({ error: "Error updating status" });
  }
});

// Both "Aprrove and Recommend to L2" & "Approve" Idea (Updated to handle both "Approved and Recommended to L2" and "Approved" with message)
router.post("/approveIdea", async (req, res) => {
  try {
    // Expecting ideaId, message, and adminRole (e.g. "AdminL1" or "AdminL2")
    const { ideaId, message, adminRole } = req.body;
    
    if (!ObjectId.isValid(ideaId)) {
      return res.status(400).json({ error: "Invalid Idea ID format" });
    }
    
    // First, fetch the current idea
    let idea = await Idea.findById(ideaId);
    if (!idea) {
      return res.status(404).json({ error: "Idea not found" });
    }
    
    // Generate IST timestamp as an ISO string
    const timestampIST = new Date(new Date().getTime() + 5.5 * 60 * 60 * 1000).toISOString();
    let updatedIdea;
    
    if (adminRole === "AdminL2") {
      // If AdminL2 is approving, fully approve the idea.
      updatedIdea = await Idea.findByIdAndUpdate(
        ideaId,
        { status: "Approved", approvedAt: timestampIST },
        { new: true }
      );
      
      // Fetch the idea owner details
      const user = await User.findOne({ corporateId: updatedIdea.employeeId }).lean();
      
      // Fetch both AdminL1 and AdminL2 emails from admin_credentials
      const admins = await Admin.find({ role: { $in: ["adminL1", "adminL2"] } }).select("email").lean();
      const adminEmails = admins.map(admin => admin.email).filter(email => email);
      
      // Prepare recipients: the idea owner and both admins
      const recipients = [user?.email, ...adminEmails].filter(Boolean);
      
      if (recipients.length > 0) {
        const mailOptions = {
          from: process.env.EMAIL_USER,
          to: recipients.join(", "),
          subject: "Idea Considered!",
          text: `Dear ${updatedIdea.employeeName} and Team,\n\nThanks for sharing your idea through “Green HatZ” initiative.  We appreciate your efforts and commitment towards continuous improvement.\n\nWe are glad to inform you that your idea with id "${updatedIdea.ideaId}" titled "${updatedIdea.ideaTheme}" has been considered for implementation. \n\nIf you need any support, feel free to connect.\n\nBest regards,\nAadhar Housing Finance Team`
        };
        
        // Send email (handle errors if needed)
        transporter.sendMail(mailOptions, (error) => {
          if (error) {
            console.error("❌ Email error:", error);
          }
        });
      }
      
      return res.status(200).json({ 
        message: "Idea fully approved by Admin L2 and emails sent to user and admins.", 
        idea: updatedIdea 
      });




    } else {
      // For AdminL1 (or other cases), update the idea to "Approved and Recommended to L2"
      updatedIdea = await Idea.findByIdAndUpdate(
        ideaId,
        { 
          status: "Approved and Recommended to L2", 
          recommendedAt: timestampIST,
          adminL1Message: message || ""
        },
        { new: true }
      );
      
      // Fetch user details and send an email notification
      const user = await User.findOne({ corporateId: updatedIdea.employeeId }).lean();

      // send an email notification
      if (user?.email) {
        const mailOptions = {
          from: process.env.EMAIL_USER,
          to: user.email,
          subject: "Idea Shortlisted!",
          text: `Dear ${updatedIdea.employeeName},\n\nThanks for sharing your idea through “Green HatZ” initiative. We appreciate your efforts and commitment towards continuous improvement.\n\nWe are glad to inform you that your idea with id "${updatedIdea.ideaId}" titled "${updatedIdea.ideaTheme}" has been shortlisted for further evaluation. \n\nIf you need any support, feel free to connect.\n\nBest regards,\nAadhar Housing Finance Team`
        };

        try {
          await transporter.sendMail(mailOptions);
        } catch (mailError) {
          console.error("❌ Email sending error:", mailError);
        }
      }
    }
    
    res.status(200).json({ message: "Idea approval processed and email sent.", idea: updatedIdea });


  } catch (error) {
    console.error("Error approving idea:", error);
    res.status(500).json({ error: "Internal Server Error", details: error.message });
  }
});

// Reject idea (AdminL1 - Existing functionality with dropdown)
router.put("/reject-idea/:id", async (req, res) => {
  try {
    const ideaId = req.params.id;
    const { reason } = req.body;

    if (!ObjectId.isValid(ideaId)) {
      return res.status(400).json({ error: "Invalid Idea ID format" });
    }
    if (!reason) {
      return res.status(400).json({ error: "Rejection reason is required" });
    }

    const rejectedAtIST = new Date(new Date().getTime() + 5.5 * 60 * 60 * 1000).toISOString();

    const updatedIdea = await Idea.findByIdAndUpdate(
      ideaId,
      { status: "Rejected", rejectionReason: reason, rejectedAt: rejectedAtIST },
      { new: true }
    );

    if (!updatedIdea) {
      return res.status(404).json({ error: "Idea not found" });
    }

    const user = await User.findOne({ corporateId: updatedIdea.employeeId });

    if (user?.email) {
      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: user.email,
        subject: "Idea Not Considered.",
        text: `Dear ${updatedIdea.employeeName},\n\nThanks for sharing your idea through “Green HatZ” initiative. We appreciate your efforts and commitment towards continuous improvement. \n\n\nWe regret to inform you that for the reason(s) mentioned below, your idea with id "${updatedIdea.ideaId}" titled "${updatedIdea.ideaTheme}" was not considered for further evaluation. \n\nReason: ${reason}\n\n\nWe encourage you to continue submitting your innovative ideas. Your participation is crucial to our collective growth and success. \n\nBest regards,\nAadhar Housing Finance Team`
      };

      try {
        await transporter.sendMail(mailOptions);
      } catch (mailError) {
        console.error("❌ Email sending error:", mailError);
      }
    }

    res.json({ message: "Idea rejected and timestamp stored", idea: updatedIdea });
  } catch (error) {
    console.error("Error rejecting idea:", error);
    res.status(500).json({ error: "Error rejecting idea", details: error.message });
  }
});

// New endpoint for AdminL2 rejection (Textbox reason)
router.put("/reject-idea-l2/:id", async (req, res) => {
  try {
    const ideaId = req.params.id;
    const { reason } = req.body;

    if (!ObjectId.isValid(ideaId)) {
      return res.status(400).json({ error: "Invalid Idea ID format" });
    }
    if (!reason || reason.trim() === "") {
      return res.status(400).json({ error: "Rejection reason is required" });
    }

    const rejectedAtIST = new Date(new Date().getTime() + 5.5 * 60 * 60 * 1000).toISOString();

    const updatedIdea = await Idea.findByIdAnd276Update(
      ideaId,
      { status: "Rejected", rejectionReason: reason.trim(), rejectedAt: rejectedAtIST },
      { new: true }
    );

    if (!updatedIdea) {
      return res.status(404).json({ error: "Idea not found" });
    }

    const user = await User.findOne({ corporateId: updatedIdea.employeeId });

    if (user?.email) {
      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: user.email,
        subject: "Your Idea Has Not Been Considered",
        text: `Dear ${updatedIdea.employeeName},\n\nThanks for sharing your idea through “Green HatZ” initiative. We appreciate your efforts and commitment towards continuous improvement. \n\nWe regret to inform you that for the reason(s) mentioned below, your idea with id "${updatedIdea.ideaId}"titled "${updatedIdea.ideaTheme}" was not considered for further evaluation. \n\nReason: ${reason}\n\n\nWe encourage you to continue submitting your innovative ideas. Your participation is crucial to our collective growth and success. \n\nBest regards,\nAadhar Housing Finance Team`
      };

      try {
        await transporter.sendMail(mailOptions);
      } catch (mailError) {
        console.error("❌ Email sending error:", mailError);
      }
    }

    res.json({ message: "Idea rejected by Admin L2 and timestamp stored", idea: updatedIdea });
  } catch (error) {
    console.error("Error rejecting idea by Admin L2:", error);
    res.status(500).json({ error: "Error rejecting idea", details: error.message });
  }
});

module.exports = router;


otpRoute.js:
const express = require("express");
const { User, Admin } = require("../models/userModel");
const transporter = require("../config/email");

const router = express.Router();

// Function to send OTP
const sendOtp = async (corporateId, res) => {
  try {
    let user = await User.findOne({ corporateId });
    let collection = User;

    if (!user) {
      user = await Admin.findOne({ corporateId });
      collection = Admin;
    }

    if (!user) return res.status(404).json({ message: "Corporate ID not found" });

    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    const otpExpiry = new Date(Date.now() + 300 * 1000);
    await collection.updateOne({ corporateId }, { $set: { otp, otpExpiry } });

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: user.email,
      subject: "Your OTP Code",
      text: `Your OTP is ${otp}. It expires in 5 minutes.`,
    };

    await transporter.sendMail(mailOptions);
    res.status(200).json({ message: "OTP sent successfully" });
  } catch (error) {
    console.error("Error in sendOtp:", error);
    res.status(500).json({ message: "Server error", error });
  }
};

// OTP Request
router.post("/request-otp", async (req, res) => {
  const { corporateId } = req.body;
  await sendOtp(corporateId, res);
});

// OTP Resend
router.post("/resend-otp", async (req, res) => {
  const { corporateId } = req.body;
  await sendOtp(corporateId, res);
});

// OTP Verification
router.post("/verify-otp", async (req, res) => {
  const { corporateId, otp } = req.body;
  try {
    let user = await User.findOne({ corporateId, otp });
    let collection = User;

    if (!user) {
      user = await Admin.findOne({ corporateId, otp });
      collection = Admin;
    }

    if (!user) return res.status(400).json({ message: "Invalid OTP" });
    if (user.otpExpiry < new Date()) return res.status(400).json({ message: "OTP expired" });

    await collection.updateOne({ corporateId }, { $unset: { otp: 1, otpExpiry: 1 } });
    res.status(200).json({ message: "Login successful", role: user.role });
  } catch (error) {
    console.error("Error in /verify-otp:", error);
    res.status(500).json({ message: "Server error", error });
  }
});




// Fetch user or admin details after successful login
router.post("/getUserDetails", async (req, res) => {
  const { corporateId } = req.body;

  try {
    let user = await User.findOne({ corporateId });

    if (!user) {
      user = await Admin.findOne({ corporateId }); // Check if the user is an admin
    }

    if (!user) {
      return res.status(404).json({ message: "User/Admin not found" });
    }

    res.json({
      corporateId: user.corporateId,
      employeeName: user.employeeName,
      employeeFunction: user.employeeFunction,
      location: user.location,
      role: user.role, // Now includes "adminL1" or "adminL2"
    });
  } catch (error) {
    console.error("Error in /getUserDetails:", error);
    res.status(500).json({ message: "Server Error", error });
  }
});

module.exports = router;
