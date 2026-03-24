'use strict';

const http    = require('http');
const express = require('express');
const multer  = require('multer');
const path    = require('path');
const fs      = require('fs');
const fetch   = require('node-fetch');
const yaml    = require('js-yaml');
const pty     = require('node-pty');
const WebSocket = require('ws');

const app  = express();
const PORT = process.env.UI_PORT || 8099;

// ─── Rutas de archivos ────────────────────────────────────────────────────────
// Las variables de entorno permiten sobreescribir las rutas en test local
const HA_TOKEN       = process.env.SUPERVISOR_TOKEN || '';
const HA_API         = 'http://supervisor/core/api';
const FLOORPLANS_DIR = process.env.FLOORPLANS_DIR || '/config/www/floorplans';
const LAYOUTS_FILE   = process.env.LAYOUTS_FILE   || '/data/floorplan-layouts.json';
const DATA_DIR       = path.dirname(LAYOUTS_FILE);
// En el contenedor: /usr/share/claude-terminal/web (COPY rootfs → /)
// En test local:   rootfs/usr/share/claude-terminal/web  (override con WEB_DIR)
const WEB_DIR = process.env.WEB_DIR || path.join(__dirname, '..', 'web');

[FLOORPLANS_DIR, DATA_DIR].forEach(d => {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
});

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(express.json({ limit: '50mb' }));

// ─── Archivos estáticos (planos y SPA) ───────────────────────────────────────
app.use('/floorplans', express.static(FLOORPLANS_DIR));
app.use(express.static(WEB_DIR));

// ─── Multer: subida de imágenes ───────────────────────────────────────────────
const storage = multer.diskStorage({
  destination: FLOORPLANS_DIR,
  filename: (req, file, cb) => {
    const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    cb(null, safe);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 20 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const ok = /\.(png|jpg|jpeg|gif|svg|webp)$/i.test(file.originalname);
    cb(ok ? null : new Error('Solo imágenes'), ok);
  }
});

// ─── API: Configuración del addon (tema + fuente para xterm.js) ──────────────
app.get('/api/config', (req, res) => {
  let theme = {};
  try { theme = JSON.parse(process.env.HA_THEME_JSON || '{}'); } catch {}
  res.json({
    theme,
    fontSize: parseInt(process.env.HA_FONT_SIZE || '14', 10)
  });
});

// ─── API: Subir imagen ────────────────────────────────────────────────────────
app.post('/api/floorplan/upload', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Sin archivo' });
  res.json({
    ok: true,
    filename: req.file.filename,
    url: `/floorplans/${req.file.filename}`,
    haUrl: `/local/floorplans/${req.file.filename}`
  });
});

// ─── API: Listar planos ───────────────────────────────────────────────────────
app.get('/api/floorplan/list', (req, res) => {
  try {
    const files = fs.readdirSync(FLOORPLANS_DIR)
      .filter(f => /\.(png|jpg|jpeg|gif|svg|webp)$/i.test(f))
      .map(f => ({
        filename: f,
        url: `/floorplans/${f}`,
        haUrl: `/local/floorplans/${f}`,
        size: fs.statSync(path.join(FLOORPLANS_DIR, f)).size,
        mtime: fs.statSync(path.join(FLOORPLANS_DIR, f)).mtimeMs
      }))
      .sort((a, b) => b.mtime - a.mtime);
    res.json(files);
  } catch { res.json([]); }
});

// ─── API: Eliminar plano ──────────────────────────────────────────────────────
app.delete('/api/floorplan/:filename', (req, res) => {
  const fp = path.join(FLOORPLANS_DIR, path.basename(req.params.filename));
  try { fs.unlinkSync(fp); res.json({ ok: true }); }
  catch { res.status(404).json({ error: 'No encontrado' }); }
});

// ─── API: Guardar layout ──────────────────────────────────────────────────────
app.post('/api/layout/save', (req, res) => {
  try {
    const data = fs.existsSync(LAYOUTS_FILE)
      ? JSON.parse(fs.readFileSync(LAYOUTS_FILE, 'utf8')) : {};
    const { floorplan, pins, name } = req.body;
    data[floorplan] = { name: name || floorplan, pins: pins || [], updated: Date.now() };
    fs.writeFileSync(LAYOUTS_FILE, JSON.stringify(data, null, 2));
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ─── API: Cargar layout ───────────────────────────────────────────────────────
app.get('/api/layout/:floorplan', (req, res) => {
  try {
    if (!fs.existsSync(LAYOUTS_FILE)) return res.json({ pins: [] });
    const data = JSON.parse(fs.readFileSync(LAYOUTS_FILE, 'utf8'));
    res.json(data[req.params.floorplan] || { pins: [] });
  } catch { res.json({ pins: [] }); }
});

// ─── API: Entidades de Home Assistant ────────────────────────────────────────
app.get('/api/ha/entities', async (req, res) => {
  try {
    const r = await fetch(`${HA_API}/states`, {
      headers: { Authorization: `Bearer ${HA_TOKEN}` }
    });
    const states = await r.json();
    res.json(states.map(s => ({
      entity_id: s.entity_id,
      state: s.state,
      name: s.attributes.friendly_name || s.entity_id,
      domain: s.entity_id.split('.')[0],
      icon: s.attributes.icon || null,
      unit: s.attributes.unit_of_measurement || null
    })));
  } catch (e) { res.status(500).json({ error: e.message, entities: [] }); }
});

// ─── API: Generar YAML picture-elements ──────────────────────────────────────
app.post('/api/generate/yaml', (req, res) => {
  const { floorplan, pins, title } = req.body;

  const elements = pins.map(pin => {
    const x = pin.x.toFixed(1);
    const y = pin.y.toFixed(1);
    const style = { left: `${x}%`, top: `${y}%` };

    if (pin.type === 'state-badge') return { type: 'state-badge', entity: pin.entity_id, style };

    if (pin.type === 'state-icon') {
      const el = { type: 'state-icon', entity: pin.entity_id, style: { ...style, '--mdc-icon-size': `${pin.size || 28}px` } };
      if (pin.icon) el.icon = pin.icon;
      if (pin.tap)  el.tap_action = { action: pin.tap === 'toggle' ? 'toggle' : 'more-info' };
      return el;
    }

    if (pin.type === 'icon') return {
      type: 'icon', icon: pin.icon || 'mdi:home',
      entity: pin.entity_id || undefined,
      tap_action: { action: pin.entity_id ? 'more-info' : 'none' },
      style: { ...style, color: pin.color || 'var(--primary-color)', '--mdc-icon-size': `${pin.size || 28}px` }
    };

    if (pin.type === 'service-button') return {
      type: 'service-button', title: pin.label || 'Botón',
      service: pin.service || 'light.toggle',
      service_data: pin.entity_id ? { entity_id: pin.entity_id } : {},
      style
    };

    if (pin.type === 'label') return {
      type: 'state-label', entity: pin.entity_id,
      prefix: pin.prefix || '', suffix: pin.suffix || (pin.unit ? ` ${pin.unit}` : ''),
      style: { ...style, color: pin.color || 'white', 'font-size': `${pin.fontSize || 14}px`, 'font-weight': 'bold', 'text-shadow': '1px 1px 2px black' }
    };

    return { type: 'state-badge', entity: pin.entity_id, style };
  });

  const card = {
    type: 'picture-elements',
    title: title || 'Plano',
    image: `/local/floorplans/${path.basename(floorplan)}`,
    elements
  };

  res.json({
    yaml: yaml.dump(card, { indent: 2, lineWidth: 120, skipInvalid: true }),
    json: card
  });
});

// ─── API: Guardar YAML en /config ─────────────────────────────────────────────
app.post('/api/save/yaml', (req, res) => {
  const { filename, content } = req.body;
  if (!filename || !content) return res.status(400).json({ error: 'Faltan datos' });
  const safeName = path.basename(filename).replace(/[^a-zA-Z0-9._-]/g, '_');
  const outputPath = `/config/www/floorplans/${safeName}.yaml`;
  try { fs.writeFileSync(outputPath, content, 'utf8'); res.json({ ok: true, path: outputPath }); }
  catch (e) { res.status(500).json({ error: e.message }); }
});

// ─── Fallback SPA ─────────────────────────────────────────────────────────────
app.get('*', (req, res) => {
  res.sendFile(path.join(WEB_DIR, 'index.html'));
});

// ─── Servidor HTTP ────────────────────────────────────────────────────────────
const server = http.createServer(app);

// ─── WebSocket PTY: terminal nativo sin ttyd ──────────────────────────────────
// Cada conexión WebSocket a /terminal/ws crea un proceso bash con PTY real.
// Protocolo (sin auth token, protocolo propio simple):
//   Client → Server: cadena de texto = stdin al bash
//   Client → Server: JSON {"type":"resize","cols":N,"rows":N} = redimensionar
//   Server → Client: cadena de texto = stdout del bash
const wss = new WebSocket.Server({ noServer: true });

wss.on('connection', (ws) => {
  // Siempre arrancamos bash. El usuario lanza 'claude' cuando quiera.
  // Lanzar claude directamente en RPi 3 consume demasiada RAM y activa el OOM killer.
  const workingDir = process.env.HA_WORKING_DIR || '/config';

  const env = {
    ...process.env,
    TERM:      'xterm-256color',
    COLORTERM: 'truecolor',
    LANG:      'C.UTF-8',
    HOME:      '/root',
  };

  let shell;
  try {
    shell = pty.spawn('bash', ['-i'], {
      name: 'xterm-256color',
      cols: 80,
      rows: 24,
      cwd:  workingDir,
      env,
    });
  } catch (err) {
    console.error('[PTY] Error al arrancar bash:', err.message);
    const msg = `\r\n\x1b[31m[ERROR] No se pudo iniciar el terminal:\r\n${err.message}\x1b[0m\r\n`;
    ws.send(msg);
    ws.close(1011, 'PTY spawn failed');
    return;
  }

  console.log(`[PTY] Nueva sesión bash (PID ${shell.pid})`);

  // Stdout del bash → cliente WebSocket
  shell.onData(data => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(data);
    }
  });

  // bash terminó → cerrar WebSocket
  shell.onExit(({ exitCode }) => {
    console.log(`[PTY] bash terminó (exit ${exitCode})`);
    try { ws.close(); } catch {}
  });

  // Cliente → bash
  // Optimización: solo intentamos JSON.parse si el mensaje empieza por '{'
  // (los resize messages), evitando el coste en cada pulsación de tecla.
  ws.on('message', (data) => {
    const str = typeof data === 'string' ? data : data.toString('utf8');
    if (str.charCodeAt(0) === 123) { // '{'
      try {
        const msg = JSON.parse(str);
        if (msg.type === 'resize') {
          const cols = Math.max(1, Math.min(500, msg.cols || 80));
          const rows = Math.max(1, Math.min(200, msg.rows || 24));
          shell.resize(cols, rows);
          return;
        }
      } catch {}
    }
    // stdin normal
    shell.write(str);
  });

  ws.on('close', () => {
    try { shell.kill(); } catch {}
  });

  ws.on('error', () => {
    try { shell.kill(); } catch {}
  });
});

// ─── Gestionar upgrade WebSocket ──────────────────────────────────────────────
server.on('upgrade', (req, socket, head) => {
  if (req.url === '/terminal/ws') {
    wss.handleUpgrade(req, socket, head, (ws) => {
      wss.emit('connection', ws, req);
    });
  } else {
    socket.destroy();
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[INFO] Claude HA Terminal UI → http://0.0.0.0:${PORT}`);
  console.log(`[INFO] Terminal PTY: node-pty (sin ttyd)`);
});
