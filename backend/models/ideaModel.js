// models/ideaModel.js
const pool = require('../config/db');

async function createIdea(data) {
  const sql = `INSERT INTO idea_submissions
    (employeeName, employeeId, employeeFunction, location, ideaTheme, department,
     benefitsCategory, ideaDescription, impactedProcess, expectedBenefitsValue,
     attachments, submissionDate, status, rejectionReason, rejectedAt, recommendedAt, approvedAt, adminL1Message)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
  const params = [
    data.employeeName,
    data.employeeId,
    data.employeeFunction,
    data.location,
    data.ideaTheme,
    data.department,
    data.benefitsCategory,
    data.ideaDescription,
    data.impactedProcess,
    data.expectedBenefitsValue,
    JSON.stringify(data.attachments || []),
    new Date(),
    data.status || 'Pending',
    data.rejectionReason || null,
    data.rejectedAt || null,
    data.recommendedAt || null,
    data.approvedAt || null,
    data.adminL1Message || null,
  ];
  const [result] = await pool.query(sql, params);
  return { insertId: result.insertId, ...data };
}

async function findAllIdeas() {
  const [rows] = await pool.query('SELECT * FROM idea_submissions');
  return rows;
}

async function findIdeaById(id) {
  const [rows] = await pool.query(
    'SELECT * FROM idea_submissions WHERE id = ?',
    [id]
  );
  return rows[0] || null;
}

async function findIdeasByEmployee(employeeId) {
  const [rows] = await pool.query(
    'SELECT * FROM idea_submissions WHERE employeeId = ?',
    [employeeId]
  );
  return rows;
}

async function updateIdeaStatus(id, updateData) {
  const fields = [];
  const params = [];
  for (const key in updateData) {
    fields.push(`\`${key}\` = ?`);
    params.push(updateData[key]);
  }
  params.push(id);
  const sql = `UPDATE idea_submissions SET ${fields.join(', ')} WHERE id = ?`;
  await pool.query(sql, params);
  return findIdeaById(id);
}

module.exports = {
  createIdea,
  findAllIdeas,
  findIdeaById,
  findIdeasByEmployee,
  updateIdeaStatus,
};
