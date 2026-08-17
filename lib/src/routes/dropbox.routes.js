const express = require('express');

const {
  getAccountInfo,
  listFolder,
} = require('../services/dropbox.service');

const router = express.Router();

// ============================================================
// GET DROPBOX ACCOUNT
// ============================================================

router.get('/account', async (req, res) => {
  try {
    const account = await getAccountInfo();

    res.json({
      success: true,
      data: account,
    });
  } catch (error) {
    console.error('Dropbox account error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to connect to Dropbox',
      error: error.message,
    });
  }
});

// ============================================================
// GET DROPBOX FILES
// ============================================================

router.get('/files', async (req, res) => {
  try {
    const path =
      req.query.path ||
      process.env.DROPBOX_PORTFOLIO_PATH ||
      '/THEVA_PORTFOLIO';

    const files = await listFolder(path);

    res.json({
      success: true,
      path,
      count: files.length,
      data: files,
    });
  } catch (error) {
    console.error('Dropbox files error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to list Dropbox files',
      error: error.message,
    });
  }
});

module.exports = router;