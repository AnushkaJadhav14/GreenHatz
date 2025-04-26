// routes/formRoutes.js
const express = require('express');
const multer = require('multer');
const router = express.Router();
const transporter = require('../config/email');
const { createIdea } = require('../models/ideaModel');
const { findUserByCorporateId } = require('../models/userModel');

// File storage
const storage = multer.diskStorage({
  destination: './uploads/',
  filename: (req, file, cb) => {
    if (!req.body.employeeId) return cb(new Error('Missing employeeId'));
    const safeName = file.originalname.replace(/\s+/g, '_');
    cb(null, `${req.body.employeeId}_${safeName}`);
  },
});
const upload = multer({ storage });

router.post('/submit-form', upload.array('attachments', 10), async (req, res) => {
  try {
    const { employeeId } = req.body;
    if (!employeeId) return res.status(400).json({ message: 'Employee ID is required' });

    const attachments = (req.files || []).map(f => f.filename);
    const ideaData = { ...req.body, attachments };
    const result = await createIdea(ideaData);

    const user = await findUserByCorporateId(employeeId);
    if (user?.email) {
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: user.email,
        subject: 'Thank You for Your Idea Submission',
        text: `Hello ${user.employeeName},\n\nThank you for submitting your idea. Your Idea ID is ${result.insertId}.`,
      });
    }

    res.status(201).json({ message: 'Form submitted successfully', ideaId: result.insertId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error submitting form', error: err.message });
  }
});

router.get('/submissions', async (req, res) => {
  const ideas = await require('../models/ideaModel').findAllIdeas();
  res.json(ideas);
});

module.exports = router;
