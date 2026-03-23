'use strict';

const express    = require('express');
const multer     = require('multer');
const path       = require('path');
const fs         = require('fs');
const fetch      = require('node-fetch');
const yaml       = require('js-yaml');
const cors       = require('cors');
const morgan     = require('morgan');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = process.env.UI_PORT || 8099;

// ─── Rutas de archivos ────────────────────────────────────────────────────────
const HA_TOKEN      = process.env.SUPERVISOR_TOKEN || '';
const HA_API        = 'http://supervisor/core/api';
const FLOORPLANS_DIR = '/config/www/floorplans';
const LAYOUTS_FILE  = '/data/floorplan-layouts.json';
const WEB_DIR       = path.join(__dirname, '..', 'web');

// Crear directorios si no existen
[FLOORPLANS_DIR, '/data'].forEach(d => {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
});

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors());
app.use(morgan('tiny'));
app.use(express.json({ limit: '50mb' }));

// Servir imágenes de planos desde /config/www/floorplans
app.use('/floorplans', express.static(FLOORPLANS_DIR));

// Proxy del terminal ttyd
app.use('/terminal', createProxyMiddleware({
  target: 'http://localhost:7681',
  ws: true,
  changeOrigin: true,
  pathRewrite: { '^/terminal': '' },
  logLevel: 'silent'
}));

// Servir la SPA principal
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
  limits: { fileSize: 20 * 1024 * 1024 }, // 20 MB
  fileFilter: (req, file, cb) => {
    const ok = /\.(png|jpg|jpeg|gif|svg|webp)$/i.test(file.originalname);
    cb(ok ? null : new Error('Solo se permiten imágenes'), ok);
  }
});

// ─── API: Subir imagen de plano ───────────────────────────────────────────────
app.post('/api/floorplan/upload', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Sin archivo' });
  res.json({
    ok: true,
    filename: req.file.filename,
    url: `/floorplans/${req.file.filename}`,
    haUrl: `/local/floorplans/${req.file.filename}`
  });
});

// ─── API: Listar planos subidos ───────────────────────────────────────────────
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
  } catch (e) {
    res.json([]);
  }
});

// ─── API: Eliminar plano ──────────────────────────────────────────────────────
app.delete('/api/floorplan/:filename', (req, res) => {
  const fp = path.join(FLOORPLANS_DIR, path.basename(req.params.filename));
  try {
    fs.unlinkSync(fp);
    res.json({ ok: true });
  } catch (e) {
    res.status(404).json({ error: 'No encontrado' });
  }
});

// ─── API: Guardar layout de pins ─────────────────────────────────────────────
app.post('/api/layout/save', (req, res) => {
  try {
    const data = fs.existsSync(LAYOUTS_FILE)
      ? JSON.parse(fs.readFileSync(LAYOUTS_FILE, 'utf8'))
      : {};
    const { floorplan, pins, name } = req.body;
    data[floorplan] = { name: name || floorplan, pins: pins || [], updated: Date.now() };
    fs.writeFileSync(LAYOUTS_FILE, JSON.stringify(data, null, 2));
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── API: Cargar layout de pins ──────────────────────────────────────────────
app.get('/api/layout/:floorplan', (req, res) => {
  try {
    if (!fs.existsSync(LAYOUTS_FILE)) return res.json({ pins: [] });
    const data = JSON.parse(fs.readFileSync(LAYOUTS_FILE, 'utf8'));
    res.json(data[req.params.floorplan] || { pins: [] });
  } catch (e) {
    res.json({ pins: [] });
  }
});

// ─── API: Entidades de Home Assistant ────────────────────────────────────────
app.get('/api/ha/entities', async (req, res) => {
  try {
    const r = await fetch(`${HA_API}/states`, {
      headers: { Authorization: `Bearer ${HA_TOKEN}` }
    });
    const states = await r.json();
    const entities = states.map(s => ({
      entity_id: s.entity_id,
      state: s.state,
      name: s.attributes.friendly_name || s.entity_id,
      domain: s.entity_id.split('.')[0],
      icon: s.attributes.icon || null,
      unit: s.attributes.unit_of_measurement || null
    }));
    res.json(entities);
  } catch (e) {
    res.status(500).json({ error: e.message, entities: [] });
  }
});

// ─── API: Generar YAML de picture-elements ───────────────────────────────────
app.post('/api/generate/yaml', (req, res) => {
  const { floorplan, pins, title } = req.body;

  const elements = pins.map(pin => {
    const x = pin.x.toFixed(1);
    const y = pin.y.toFixed(1);

    if (pin.type === 'state-badge') {
      return {
        type: 'state-badge',
        entity: pin.entity_id,
        style: { left: `${x}%`, top: `${y}%` }
      };
    }

    if (pin.type === 'state-icon') {
      const el = {
        type: 'state-icon',
        entity: pin.entity_id,
        style: { left: `${x}%`, top: `${y}%`, '--mdc-icon-size': '28px' }
      };
      if (pin.icon)  el.icon = pin.icon;
      if (pin.tap)   el.tap_action = { action: pin.tap === 'toggle' ? 'toggle' : 'more-info' };
      return el;
    }

    if (pin.type === 'icon') {
      return {
        type: 'icon',
        icon: pin.icon || 'mdi:home',
        entity: pin.entity_id || undefined,
        title: pin.label || undefined,
        tap_action: { action: pin.entity_id ? 'more-info' : 'none' },
        style: {
          left: `${x}%`, top: `${y}%`,
          color: pin.color || 'var(--primary-color)',
          '--mdc-icon-size': `${pin.size || 28}px`
        }
      };
    }

    if (pin.type === 'service-button') {
      return {
        type: 'service-button',
        title: pin.label || 'Botón',
        service: pin.service || 'light.toggle',
        service_data: pin.entity_id ? { entity_id: pin.entity_id } : {},
        style: { left: `${x}%`, top: `${y}%` }
      };
    }

    if (pin.type === 'label') {
      return {
        type: 'state-label',
        entity: pin.entity_id,
        prefix: pin.prefix || '',
        suffix: pin.suffix || (pin.unit ? ` ${pin.unit}` : ''),
        style: {
          left: `${x}%`, top: `${y}%`,
          color: pin.color || 'white',
          'font-size': `${pin.fontSize || 14}px`,
          'font-weight': 'bold',
          'text-shadow': '1px 1px 2px black'
        }
      };
    }

    // default: state-badge
    return {
      type: 'state-badge',
      entity: pin.entity_id,
      style: { left: `${x}%`, top: `${y}%` }
    };
  });

  const card = {
    type: 'picture-elements',
    title: title || 'Plano',
    image: `/local/floorplans/${path.basename(floorplan)}`,
    elements
  };

  // Limpiar propiedades undefined
  const cleanYaml = yaml.dump(card, {
    indent: 2,
    lineWidth: 120,
    skipInvalid: true,
    replacer: (key, val) => val === undefined ? undefined : val
  });

  res.json({ yaml: cleanYaml, json: card });
});

// ─── API: Guardar YAML en /config ────────────────────────────────────────────
app.post('/api/save/yaml', (req, res) => {
  const { filename, content } = req.body;
  if (!filename || !content) return res.status(400).json({ error: 'Faltan datos' });

  const safeName = path.basename(filename).replace(/[^a-zA-Z0-9._-]/g, '_');
  const outputPath = `/config/www/floorplans/${safeName}.yaml`;

  try {
    fs.writeFileSync(outputPath, content, 'utf8');
    res.json({ ok: true, path: outputPath });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ─── Fallback SPA ─────────────────────────────────────────────────────────────
app.get('*', (req, res) => {
  res.sendFile(path.join(WEB_DIR, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Claude HA Terminal UI → http://0.0.0.0:${PORT}`);
});
