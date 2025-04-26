// models/userModel.js
const pool = require('../config/db');

async function findUserByCorporateId(corporateId) {
  const [rows] = await pool.query(
    'SELECT * FROM user_credentials WHERE corporateId = ?',
    [corporateId]
  );
  return rows[0] || null;
}

async function findAdminByCorporateId(corporateId) {
  const [rows] = await pool.query(
    'SELECT * FROM admin_credentials WHERE corporateId = ?',
    [corporateId]
  );
  return rows[0] || null;
}

async function updateUserOtp(corporateId, otp, otpExpiry) {
  await pool.query(
    'UPDATE user_credentials SET otp = ?, otpExpiry = ? WHERE corporateId = ?',
    [otp, otpExpiry, corporateId]
  );
}

async function updateAdminOtp(corporateId, otp, otpExpiry) {
  await pool.query(
    'UPDATE admin_credentials SET otp = ?, otpExpiry = ? WHERE corporateId = ?',
    [otp, otpExpiry, corporateId]
  );
}

module.exports = {
  findUserByCorporateId,
  findAdminByCorporateId,
  updateUserOtp,
  updateAdminOtp,
};
