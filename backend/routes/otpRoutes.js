// routes/otpRoutes.js
const express = require('express');
const router = express.Router();
const transporter = require('../config/email');
const {
  findUserByCorporateId,
  findAdminByCorporateId,
  updateUserOtp,
  updateAdminOtp,
} = require('../models/userModel');

async function sendOtp(corporateId, res) {
  let user = await findUserByCorporateId(corporateId);
  let isAdmin = false;
  if (!user) {
    user = await findAdminByCorporateId(corporateId);
    isAdmin = true;
  }
  if (!user) return res.status(404).json({ message: 'Corporate ID not found' });

  const otp = Math.floor(1000 + Math.random() * 9000).toString();
  const otpExpiry = new Date(Date.now() + 5 * 60 * 1000);

  if (isAdmin) await updateAdminOtp(corporateId, otp, otpExpiry);
  else await updateUserOtp(corporateId, otp, otpExpiry);

  await transporter.sendMail({
    from: process.env.EMAIL_USER,
    to: user.email,
    subject: 'Your OTP Code',
    text: `Your OTP is ${otp}. It expires in 5 minutes.`,
  });

  res.json({ message: 'OTP sent successfully' });
}

router.post('/request-otp', (req, res) => sendOtp(req.body.corporateId, res));
router.post('/resend-otp', (req, res) => sendOtp(req.body.corporateId, res));

router.post('/verify-otp', async (req, res) => {
  const { corporateId, otp } = req.body;
  let user = await findUserByCorporateId(corporateId);
  let isAdmin = false;
  if (!user) {
    user = await findAdminByCorporateId(corporateId);
    isAdmin = true;
  }
  if (!user || user.otp !== otp) return res.status(400).json({ message: 'Invalid OTP' });
  if (new Date(user.otpExpiry) < new Date()) return res.status(400).json({ message: 'OTP expired' });

  // clear OTP fields
  if (isAdmin) await updateAdminOtp(corporateId, null, null);
  else await updateUserOtp(corporateId, null, null);

  res.json({ message: 'Login successful', role: user.role });
});

router.post('/getUserDetails', async (req, res) => {
  const { corporateId } = req.body;
  const user = await findUserByCorporateId(corporateId) || await findAdminByCorporateId(corporateId);
  if (!user) return res.status(404).json({ message: 'User/Admin not found' });

  const { employeeName, employeeFunction, location, role } = user;
  res.json({ corporateId, employeeName, employeeFunction, location, role });
});

module.exports = router;
