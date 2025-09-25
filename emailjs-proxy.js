// Simple Node.js proxy service for EmailJS
// Deploy this to Vercel, Netlify, or any Node.js hosting service

const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all routes
app.use(cors());
app.use(express.json());

// EmailJS proxy endpoint
app.post('/send-email', async (req, res) => {
  try {
    const { email, otp, service_id, template_id, user_id } = req.body;
    
    // Validate required fields
    if (!email || !otp || !service_id || !template_id || !user_id) {
      return res.status(400).json({ 
        error: 'Missing required fields: email, otp, service_id, template_id, user_id' 
      });
    }
    
    // Prepare EmailJS request
    const emailjsData = {
      service_id: service_id,
      template_id: template_id,
      user_id: user_id,
      template_params: {
        to_email: email,
        otp_code: otp,
        app_name: 'Campus Food App',
        from_name: 'Campus Food App Team',
        subject: 'Verification Code - Campus Food App',
        message: `Your verification code is: ${otp}\n\nThis code will expire in 10 minutes.\n\nIf you did not request this code, please ignore this email.\n\nBest regards,\nCampus Food App Team`,
      },
    };
    
    // Send request to EmailJS
    const response = await axios.post('https://api.emailjs.com/api/v1.0/email/send', emailjsData, {
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'https://your-domain.com', // Replace with your actual domain
      },
    });
    
    if (response.status === 200) {
      console.log(`Email sent successfully to ${email}`);
      res.json({ success: true, message: 'Email sent successfully' });
    } else {
      console.error('EmailJS error:', response.status, response.data);
      res.status(500).json({ error: 'Failed to send email' });
    }
    
  } catch (error) {
    console.error('Proxy error:', error.message);
    res.status(500).json({ 
      error: 'Internal server error', 
      details: error.message 
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`EmailJS Proxy Server running on port ${PORT}`);
});

module.exports = app;
