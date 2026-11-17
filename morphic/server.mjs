// Front proxy for Morphic on Railway.
// Starts Next.js on 127.0.0.1:$MORPHIC_INTERNAL_PORT and serves the public
// port $PORT (dual-stack). Every request is passed through unchanged
// (streaming included), except Morphic's /api/advanced-search route: it runs
// searches and crawls pages for any caller without a login, so it is only
// reachable from inside the container (the app calls it on the internal port).
import { spawn } from 'node:child_process'
import http from 'node:http'

const PUBLIC_PORT = Number(process.env.PORT || 3000)
const APP_PORT = Number(process.env.MORPHIC_INTERNAL_PORT || 3001)
const BLOCKED = ['/api/advanced-search']

const next = spawn(
  '/app/node_modules/.bin/next',
  ['start', '-H', '127.0.0.1', '-p', String(APP_PORT)],
  { cwd: '/app', stdio: 'inherit', env: { ...process.env, PORT: String(APP_PORT) } }
)
next.on('exit', (code, signal) => {
  console.error(`[railway] next exited (code ${code}, signal ${signal})`)
  process.exit(code ?? 1)
})
for (const sig of ['SIGTERM', 'SIGINT']) {
  process.on(sig, () => {
    next.kill(sig)
    setTimeout(() => process.exit(0), 15000).unref()
  })
}

function isBlocked(rawUrl) {
  let path = (rawUrl || '/').split('?')[0].split('#')[0]
  try {
    path = decodeURIComponent(path)
  } catch {
    return true
  }
  path = path.replace(/\\/g, '/').replace(/\/+/g, '/').replace(/\/$/, '').toLowerCase()
  return BLOCKED.some(p => path === p || path.startsWith(p + '/'))
}

const server = http.createServer((req, res) => {
  if (isBlocked(req.url)) {
    res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' })
    res.end('Not found\n')
    return
  }
  const upstream = http.request(
    { host: '127.0.0.1', port: APP_PORT, method: req.method, path: req.url, headers: req.headers },
    up => {
      res.writeHead(up.statusCode || 502, up.statusMessage, up.rawHeaders)
      up.pipe(res)
    }
  )
  upstream.on('error', () => {
    if (!res.headersSent) {
      res.writeHead(503, { 'content-type': 'text/plain; charset=utf-8', 'retry-after': '5' })
      res.end('Morphic is starting\n')
    } else {
      res.destroy()
    }
  })
  res.on('close', () => {
    if (!res.writableFinished) upstream.destroy()
  })
  req.pipe(upstream)
})
// Chat answers stream for minutes: no request timeout on the proxy.
server.requestTimeout = 0
server.headersTimeout = 66_000
server.keepAliveTimeout = 65_000
server.listen(PUBLIC_PORT, '::', () => {
  console.log(`[railway] proxy on :${PUBLIC_PORT} -> next on 127.0.0.1:${APP_PORT}`)
})
