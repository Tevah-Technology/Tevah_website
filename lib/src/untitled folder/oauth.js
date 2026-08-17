require('dotenv').config();

const {
  Dropbox,
  DropboxAuth,
} = require('dropbox');

const readline =
  require('readline');

const auth =
  new DropboxAuth({
    clientId:
      process.env.DROPBOX_APP_KEY,

    clientSecret:
      process.env.DROPBOX_APP_SECRET,
  });

const authUrl =
  auth.getAuthenticationUrl(
    'http://localhost:3000/oauth/callback',
    undefined,
    'code',
    'offline',
  );

console.log('');
console.log(
  'Open this URL in your browser:',
);
console.log('');
console.log(authUrl);
console.log('');
console.log(
  'After authorization, Dropbox will redirect to:',
);
console.log(
  'http://localhost:3000/oauth/callback?code=...',
);
console.log('');