const fs = require('fs');
const path = require('path');

const outDir = path.join(__dirname, '..', 'assets');
const outPath = path.join(outDir, 'study_area_map.svg');

const marker = {
  lon: 80.031361,
  lat: 9.667111,
  dms: `9°40'01.6"N, 80°01'52.9"E`,
};

const landColor = '#FADBD8';
const waterColor = '#EAF2F8';
const borderColor = '#111111';
const red = '#d71920';
const gridColor = '#8d9aa3';

const width = 1600;
const height = 950;
const panelTop = 115;
const panelWidth = 690;
const panelHeight = 680;
const leftX = 80;
const rightX = 830;

const overview = { west: 79.2, east: 82.3, south: 5.5, north: 10.5 };
const detail = { west: 79.5, east: 81.25, south: 9.25, north: 10.0 };

function project(bounds, x0, y0, panelW, panelH, lon, lat) {
  return [
    x0 + ((lon - bounds.west) / (bounds.east - bounds.west)) * panelW,
    y0 + ((bounds.north - lat) / (bounds.north - bounds.south)) * panelH,
  ];
}

function poly(bounds, x0, y0, panelW, panelH, coords) {
  return coords.map(([lon, lat]) => {
    const [x, y] = project(bounds, x0, y0, panelW, panelH, lon, lat);
    return `${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(' ');
}

function rectFromBounds(panelBounds, x0, y0, panelW, panelH, boxBounds) {
  const [x1, y1] = project(panelBounds, x0, y0, panelW, panelH, boxBounds.west, boxBounds.north);
  const [x2, y2] = project(panelBounds, x0, y0, panelW, panelH, boxBounds.east, boxBounds.south);
  return {
    x: Math.min(x1, x2),
    y: Math.min(y1, y2),
    width: Math.abs(x2 - x1),
    height: Math.abs(y2 - y1),
  };
}

const sriLanka = [
  [79.75, 9.82], [79.93, 9.70], [80.10, 9.46], [80.28, 9.12],
  [80.47, 8.70], [80.61, 8.23], [80.75, 7.72], [80.83, 7.18],
  [80.81, 6.72], [80.68, 6.32], [80.39, 6.05], [80.02, 5.95],
  [79.77, 6.12], [79.61, 6.52], [79.55, 7.06], [79.62, 7.72],
  [79.70, 8.30], [79.68, 8.82], [79.62, 9.26],
];

const jaffna = [
  [79.62, 9.77], [79.73, 9.88], [79.93, 9.94], [80.23, 9.96],
  [80.51, 9.93], [80.82, 9.86], [81.08, 9.78], [81.17, 9.68],
  [81.04, 9.57], [80.77, 9.51], [80.45, 9.48], [80.18, 9.52],
  [79.93, 9.56], [79.72, 9.62],
];

const islands = [
  [[79.67, 9.64], [79.78, 9.68], [79.91, 9.69], [80.03, 9.67], [80.13, 9.62], [80.02, 9.60], [79.85, 9.59]],
  [[79.62, 9.45], [79.72, 9.47], [79.81, 9.44], [79.76, 9.38], [79.63, 9.39]],
  [[79.86, 9.39], [79.95, 9.41], [80.03, 9.38], [79.98, 9.34], [79.86, 9.35]],
];

const mainlandNorth = [
  [79.54, 9.46], [79.75, 9.42], [80.01, 9.40], [80.32, 9.38],
  [80.68, 9.34], [81.02, 9.30], [81.22, 9.25], [79.54, 9.25],
];

function grid(bounds, x0, y0, panelW, panelH, lonTicks, latTicks) {
  const lines = [];
  for (const lon of lonTicks) {
    const [x] = project(bounds, x0, y0, panelW, panelH, lon, bounds.south);
    lines.push(`<line x1="${x.toFixed(1)}" y1="${y0}" x2="${x.toFixed(1)}" y2="${y0 + panelH}" stroke="${gridColor}" stroke-width="1" stroke-dasharray="7 7" opacity="0.65"/>`);
    lines.push(`<text x="${(x - 31).toFixed(1)}" y="${y0 - 18}" class="tick">${lon.toFixed(1)}°E</text>`);
  }
  for (const lat of latTicks) {
    const [, y] = project(bounds, x0, y0, panelW, panelH, bounds.west, lat);
    lines.push(`<line x1="${x0}" y1="${y.toFixed(1)}" x2="${x0 + panelW}" y2="${y.toFixed(1)}" stroke="${gridColor}" stroke-width="1" stroke-dasharray="7 7" opacity="0.65"/>`);
    lines.push(`<text x="${x0 - 66}" y="${(y + 7).toFixed(1)}" class="tick">${lat.toFixed(2)}°N</text>`);
  }
  return lines.join('\n');
}

function northArrow(x, y) {
  return `
  <g transform="translate(${x}, ${y})">
    <path d="M38 0 L70 112 L38 86 L6 112 Z" fill="#ffffff" stroke="${borderColor}" stroke-width="5"/>
    <text x="29" y="146" class="label">N</text>
  </g>`;
}

function scaleBar(x, y, label) {
  return `
  <g transform="translate(${x}, ${y})">
    <line x1="0" y1="0" x2="145" y2="0" stroke="${borderColor}" stroke-width="7"/>
    <line x1="0" y1="-13" x2="0" y2="13" stroke="${borderColor}" stroke-width="4"/>
    <line x1="145" y1="-13" x2="145" y2="13" stroke="${borderColor}" stroke-width="4"/>
    <text x="-5" y="38" class="small">0</text>
    <text x="93" y="38" class="small">${label}</text>
  </g>`;
}

const overviewBox = rectFromBounds(overview, leftX, panelTop, panelWidth, panelHeight, detail);
const [overviewMarkerX, overviewMarkerY] = project(overview, leftX, panelTop, panelWidth, panelHeight, marker.lon, marker.lat);
const [detailMarkerX, detailMarkerY] = project(detail, rightX, panelTop, panelWidth, panelHeight, marker.lon, marker.lat);

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-label="Scientific two-panel study-area map with square marker at sample collection location">
  <style>
    .title { font-family: "Times New Roman", serif; font-size: 32px; font-weight: 700; fill: #111; }
    .subtitle { font-family: "Times New Roman", serif; font-size: 25px; font-weight: 700; fill: #111; }
    .label { font-family: "Times New Roman", serif; font-size: 24px; font-weight: 700; fill: #111; }
    .small { font-family: "Times New Roman", serif; font-size: 22px; fill: #111; }
    .tick { font-family: "Times New Roman", serif; font-size: 18px; fill: #222; }
  </style>
  <rect width="${width}" height="${height}" fill="#ffffff"/>
  <text x="${leftX}" y="56" class="title">Figure 2a: Study Area Overview (Sri Lanka)</text>
  <text x="${rightX}" y="56" class="title">Figure 2b: Detailed Jaffna Peninsula</text>

  <rect x="${leftX}" y="${panelTop}" width="${panelWidth}" height="${panelHeight}" fill="${waterColor}" stroke="${borderColor}" stroke-width="3"/>
  ${grid(overview, leftX, panelTop, panelWidth, panelHeight, [80, 81, 82], [6, 7, 8, 9, 10])}
  <polygon points="${poly(overview, leftX, panelTop, panelWidth, panelHeight, sriLanka)}" fill="${landColor}" stroke="${borderColor}" stroke-width="3"/>
  <rect x="${overviewBox.x.toFixed(1)}" y="${overviewBox.y.toFixed(1)}" width="${overviewBox.width.toFixed(1)}" height="${overviewBox.height.toFixed(1)}" fill="none" stroke="${red}" stroke-width="4"/>
  <rect x="${(overviewMarkerX - 8).toFixed(1)}" y="${(overviewMarkerY - 8).toFixed(1)}" width="16" height="16" fill="${red}" stroke="${borderColor}" stroke-width="2"/>
  ${northArrow(leftX + panelWidth - 95, panelTop + 40)}
  ${scaleBar(leftX + 45, panelTop + panelHeight - 62, '100 km')}
  <text x="${leftX + 275}" y="${panelTop + 370}" class="label">Sri Lanka</text>

  <rect x="${rightX}" y="${panelTop}" width="${panelWidth}" height="${panelHeight}" fill="${waterColor}" stroke="${borderColor}" stroke-width="3"/>
  ${grid(detail, rightX, panelTop, panelWidth, panelHeight, [79.5, 80.0, 80.5, 81.0], [9.25, 9.50, 9.75, 10.00])}
  <polygon points="${poly(detail, rightX, panelTop, panelWidth, panelHeight, mainlandNorth)}" fill="${landColor}" stroke="${borderColor}" stroke-width="2.5"/>
  <polygon points="${poly(detail, rightX, panelTop, panelWidth, panelHeight, jaffna)}" fill="${landColor}" stroke="${borderColor}" stroke-width="3"/>
  ${islands.map((coords) => `<polygon points="${poly(detail, rightX, panelTop, panelWidth, panelHeight, coords)}" fill="${landColor}" stroke="${borderColor}" stroke-width="2.5"/>`).join('\n  ')}
  <rect x="${rightX}" y="${panelTop}" width="${panelWidth}" height="${panelHeight}" fill="none" stroke="${red}" stroke-width="4"/>
  <rect x="${(detailMarkerX - 16).toFixed(1)}" y="${(detailMarkerY - 16).toFixed(1)}" width="32" height="32" fill="${red}" stroke="#ffffff" stroke-width="5"/>
  <line x1="${detailMarkerX.toFixed(1)}" y1="${(detailMarkerY - 23).toFixed(1)}" x2="${(detailMarkerX + 42).toFixed(1)}" y2="${(detailMarkerY - 78).toFixed(1)}" stroke="${red}" stroke-width="3"/>
  <rect x="${(detailMarkerX + 48).toFixed(1)}" y="${(detailMarkerY - 118).toFixed(1)}" width="360" height="94" rx="7" fill="#ffffff" stroke="${borderColor}" stroke-width="2"/>
  <text x="${(detailMarkerX + 66).toFixed(1)}" y="${(detailMarkerY - 82).toFixed(1)}" class="label">Precise Study Point</text>
  <text x="${(detailMarkerX + 66).toFixed(1)}" y="${(detailMarkerY - 48).toFixed(1)}" class="small">${marker.dms}</text>
  <text x="${rightX + 210}" y="${panelTop + 155}" class="label">Jaffna Peninsula</text>
  <text x="${rightX + 82}" y="${panelTop + 530}" class="label">Palk Strait</text>
  <text x="${rightX + 110}" y="${panelTop + 380}" class="small">Velanai / Thurayoor</text>
  ${northArrow(rightX + panelWidth - 95, panelTop + 40)}
  ${scaleBar(rightX + 45, panelTop + panelHeight - 62, '10 km')}

  <g transform="translate(${width - 430}, ${height - 95})">
    <rect x="0" y="0" width="30" height="30" fill="${landColor}" stroke="${borderColor}" stroke-width="2"/>
    <text x="44" y="24" class="small">Sri Lanka land</text>
    <rect x="0" y="45" width="30" height="30" fill="none" stroke="${red}" stroke-width="4"/>
    <text x="44" y="69" class="small">Study area extent</text>
    <rect x="0" y="90" width="30" height="30" fill="${red}" stroke="#ffffff" stroke-width="4"/>
    <text x="44" y="114" class="small">Square marker: precise study point</text>
  </g>
</svg>
`;

fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(outPath, svg);
console.log(`Generated ${outPath}`);
