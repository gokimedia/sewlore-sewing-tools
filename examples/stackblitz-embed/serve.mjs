import { createServer } from 'node:http';
import { readFile, realpath, stat } from 'node:fs/promises';
import { dirname, extname, isAbsolute, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = await realpath(dirname(fileURLToPath(import.meta.url)));
const port = Number(process.env.PORT ?? 3000);
if (!Number.isInteger(port) || port < 0 || port > 65535) {
  console.error('PORT must be an integer from 0 to 65535. Use 0 for an available local port.');
  process.exit(1);
}

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.md': 'text/plain; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
};

function isWithinRoot(file) {
  const child = relative(root, file);
  return child !== '..' && !child.startsWith('../') && !child.startsWith('..\\') && !isAbsolute(child);
}

function sendText(request, response, code, message, headers = {}) {
  response.writeHead(code, {
    'Content-Type': 'text/plain; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    ...headers,
  });
  response.end(request.method === 'HEAD' ? undefined : `${message}\n`);
}

const server = createServer(async (request, response) => {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    sendText(request, response, 405, 'Method not allowed', { Allow: 'GET, HEAD' });
    return;
  }

  let path;
  try {
    // Inspect the raw path before URL normalization can remove dot segments.
    path = decodeURIComponent((request.url ?? '/').split(/[?#]/, 1)[0]);
  } catch {
    sendText(request, response, 400, 'Invalid path encoding');
    return;
  }
  if (!path.startsWith('/') || path.includes('\0')) {
    sendText(request, response, 400, 'Invalid path');
    return;
  }
  // Reject Windows separators, drive/stream syntax and traversal on every platform.
  if (path.includes('\\') || path.includes(':') || path.split('/').some(part => part === '.' || part === '..')) {
    sendText(request, response, 403, 'Path outside example is not allowed');
    return;
  }
  const candidate = resolve(root, `.${path === '/' ? '/index.html' : path}`);
  if (!isWithinRoot(candidate)) {
    sendText(request, response, 403, 'Path outside example is not allowed');
    return;
  }

  try {
    // Resolve symlinks too; even a link inside the example cannot expose its parent.
    const file = await realpath(candidate);
    if (!isWithinRoot(file)) {
      sendText(request, response, 403, 'Path outside example is not allowed');
      return;
    }
    const details = await stat(file);
    if (!details.isFile()) {
      sendText(request, response, 404, 'File not found');
      return;
    }
    const data = request.method === 'HEAD' ? null : await readFile(file);
    response.writeHead(200, {
      'Content-Type': mimeTypes[extname(file).toLowerCase()] ?? 'application/octet-stream',
      'Content-Length': details.size,
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    });
    response.end(data);
  } catch (error) {
    const code = error.code === 'ENOENT' || error.code === 'ENOTDIR' ? 404
      : error.code === 'EACCES' || error.code === 'EPERM' ? 403 : 500;
    sendText(request, response, code, code === 404 ? 'File not found'
      : code === 403 ? 'File access denied' : 'Unable to load file');
  }
});

server.on('error', error => {
  console.error(`Server could not start: ${error.code ?? 'unknown error'}`);
  process.exit(1);
});
server.listen(port, '0.0.0.0', () => {
  console.log(`Sewlore embed example: http://localhost:${server.address().port}`);
});
