// server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');

const otpRoutes  = require('./routes/otpRoutes');
const formRoutes = require('./routes/formRoutes');
const ideaRoutes = require('./routes/ideaRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads'));

app.use('/', otpRoutes);
app.use('/', formRoutes);
app.use('/', ideaRoutes);

app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
