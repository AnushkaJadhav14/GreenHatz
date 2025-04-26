const express = require('express');
const router = express.Router();
const {
  findAllIdeas,
  findIdeaById,
  findIdeasByEmployee,
  updateIdeaStatus,
} = require('../models/ideaModel');

// Fetch all ideas
router.get('/ideas', async (req, res) => {
  const ideas = await findAllIdeas();
  res.json(ideas);
});

// Fetch a single idea by ID
router.get('/idea/:id', async (req, res) => {
  const idea = await findIdeaById(req.params.id);
  if (!idea) return res.status(404).json({ error: 'Idea not found' });
  res.json(idea);
});

// Fetch ideas for a specific employee
router.get('/user-ideas/:employeeId', async (req, res) => {
  const ideas = await findIdeasByEmployee(req.params.employeeId);
  const approved = ideas.filter(i => i.status === 'Approved').length;
  const rejected = ideas.filter(i => i.status === 'Rejected').length;
  res.json({ totalIdeas: ideas.length, approvedCount: approved, rejectedCount: rejected, ideas });
});

// General status update
router.put('/update-status/:id', async (req, res) => {
  const { status, rejectionReason } = req.body;
  if (!['Approved', 'Rejected', 'Recommended', 'Pending'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }
  const update = { status };
  if (status === 'Rejected') update.rejectionReason = rejectionReason;
  const idea = await updateIdeaStatus(req.params.id, update);
  res.json({ message: 'Idea status updated', idea });
});

// Admin L1 approve and recommend to L2
router.post('/approveIdea', async (req, res) => {
  try {
    const { ideaId, message } = req.body;
    if (!ideaId) return res.status(400).json({ error: 'ideaId is required' });

    const update = {
      status: 'Recommended',
      adminL1Message: message || null,
      recommendedAt: new Date(),
    };

    const idea = await updateIdeaStatus(ideaId, update);
    res.json({ message: 'Idea approved and recommended to L2', idea });
  } catch (err) {
    console.error('Error in /approveIdea:', err);
    res.status(500).json({ error: 'Failed to approve idea' });
  }
});

// Admin L1 reject idea with reason
router.put('/reject-ideas/:id', async (req, res) => {
  try {
    const { reason } = req.body;
    if (!reason) return res.status(400).json({ error: 'Rejection reason required' });

    const update = {
      status: 'Rejected',
      rejectionReason: reason,
      rejectedAt: new Date(),
    };

    const idea = await updateIdeaStatus(req.params.id, update);
    res.json({ message: 'Idea rejected', idea });
  } catch (err) {
    console.error('Error in /reject-ideas/:id:', err);
    res.status(500).json({ error: 'Failed to reject idea' });
  }
});

module.exports = router;
