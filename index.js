const http = require('http');
const port = process.env.PORT || 3000;

try {
  require('newrelic');
} catch (error) {
  console.error('Error initializing New Relic:', error.message);
}

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  const msg = 'Hello Node!\n';
  res.end(msg);
});

server.listen(port, () => {
  console.log(`Server running on http://localhost:${port}/`);
});
