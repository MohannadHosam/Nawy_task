const http = require('http');
const port = process.env.PORT || 3000;

// try {
//   require('newrelic');
// } catch (error) {
//   console.error('Error initializing New Relic:', error.message);
// }

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  const msg = 'Hello Node version 3!\n';
  const msg2 = 'This is the second message!\n';
  res.end(msg + msg2);
});

server.listen(port, () => {
  console.log(`Server running on http://localhost:${port}/`);
});
