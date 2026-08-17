const express = require('express');

const {
  getPortfolio,
} = require('../services/dropbox.service');

const router = express.Router();

// ============================================================
// GET PORTFOLIO
// ============================================================

router.get('/', async (req, res) => {
  try {
    console.log('');
    console.log(
      'GET /api/portfolio',
    );

    const projects =
      await getPortfolio();

    res.json({
      success: true,

      count:
        projects.length,

      data:
        projects,
    });
  } catch (error) {
    console.error(
      'Portfolio error:',
      error,
    );

    res.status(500).json({
      success: false,

      message:
        'Failed to load portfolio',

      error:
        error.message,
    });
  }
});

module.exports = router;