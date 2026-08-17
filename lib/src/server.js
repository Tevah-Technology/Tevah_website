const express = require('express');
const cors = require('cors');
require('dotenv').config();

const portfolioRoutes =
  require('./routes/portfolio.routes');

const dropboxRoutes =
  require('./routes/dropbox.routes');

const app = express();

// ============================================================
// DEBUG ENVIRONMENT
// ============================================================

console.log('------------------------------------');

console.log(
  'DROPBOX_APP_KEY:',
  process.env.DROPBOX_APP_KEY
    ? 'SET'
    : 'MISSING',
);

console.log(
  'DROPBOX_APP_SECRET:',
  process.env.DROPBOX_APP_SECRET
    ? 'SET'
    : 'MISSING',
);

console.log(
  'DROPBOX_REFRESH_TOKEN:',
  process.env.DROPBOX_REFRESH_TOKEN
    ? 'SET'
    : 'MISSING',
);

console.log(
  'DROPBOX_PORTFOLIO_PATH:',
  process.env.DROPBOX_PORTFOLIO_PATH ||
    'MISSING',
);

console.log('------------------------------------');

// ============================================================
// MIDDLEWARE
// ============================================================

app.use(
  cors({
    origin: true,
    credentials: false,
  }),
);

app.use(
  express.json(),
);

app.use(
  express.urlencoded({
    extended: true,
  }),
);

// ============================================================
// HEALTH
// ============================================================

app.get(
  '/',
  (req, res) => {
    res.json({
      success: true,
      message:
        'Theva Backend is running',
    });
  },
);

app.get(
  '/health',
  (req, res) => {
    res.json({
      success: true,
      status: 'healthy',
    });
  },
);

// ============================================================
// ROUTES
// ============================================================

app.use(
  '/api/portfolio',
  portfolioRoutes,
);

app.use(
  '/api/dropbox',
  dropboxRoutes,
);

// ============================================================
// 404
// ============================================================

app.use(
  (req, res) => {
    res.status(404).json({
      success: false,
      message:
        'Route not found',
      path:
        req.originalUrl,
    });
  },
);

// ============================================================
// ERROR HANDLER
// ============================================================

app.use(
  (
    error,
    req,
    res,
    next,
  ) => {
    console.error(
      'SERVER ERROR:',
      error,
    );

    res.status(500).json({
      success: false,
      message:
        'Internal server error',
    });
  },
);

// ============================================================
// SERVER
// ============================================================

const PORT =
  process.env.PORT || 3000;

app.listen(
  PORT,
  () => {
    console.log('');
    console.log(
      '====================================',
    );
    console.log(
      '        THEVA BACKEND',
    );
    console.log(
      '====================================',
    );
    console.log(
      `Server: http://localhost:${PORT}`,
    );
    console.log(
      `Portfolio: http://localhost:${PORT}/api/portfolio`,
    );
    console.log(
      `Dropbox: http://localhost:${PORT}/api/dropbox`,
    );
    console.log(
      `Health: http://localhost:${PORT}/health`,
    );
    console.log(
      '====================================',
    );
    console.log('');
  },
);