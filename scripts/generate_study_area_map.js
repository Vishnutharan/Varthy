const fs = require('fs');
const path = require('path');

const outDir = path.join(__dirname, '..', 'assets');
const outPath = path.join(outDir, 'study_area_map.svg');

const bounds = {
  west: 79.5,
  east: 81.25,
  south: 9.25,
  north: 10.0,
};

const sample = {
  label: 'Sampling site',
  lat: 9 + 40 / 60 + 1.6 / 3600,
  lon: 80 + 1 / 60 + 52.9 / 3600,
};

const width = 1200;
const height = 650;
const margin = 90;
const mapWidth = width - margin * 2;
const mapHeight = height - margin * 2;

function x(lon) {
  return margin + ((lon - bounds.west) / (bounds.east - bounds.west)) * mapWidth;
}

function y(lat) {
  return margin + ((bounds.north - lat) / (bounds.north - bounds.south)) * mapHeight;
}

function points(coords) {
  return coords.map(([lon, lat]) => `${x(lon).toFixed(1)},${y(lat).toFixed(1)}`).join(' ');
}

const sampleX = x(sample.lon);
const sampleY = y(sample.lat);

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-label="Study area map with square marker for sampling site near the Palk Strait, Jaffna Peninsula, Sri Lanka">
  <rect width="${width}" height="${height}" fill="#eaf7fb"/>
  <rect x="${margin}" y="${margin}" width="${mapWidth}" height="${mapHeight}" fill="#d8f0f5" stroke="#2f4f5f" stroke-width="3"/>

  <g stroke="#9ab8c2" stroke-width="1.5">
    <line x1="${x(80)}" y1="${margin}" x2="${x(80)}" y2="${height - margin}"/>
    <line x1="${x(81)}" y1="${margin}" x2="${x(81)}" y2="${height - margin}"/>
    <line x1="${margin}" y1="${y(9.5)}" x2="${width - margin}" y2="${y(9.5)}"/>
    <line x1="${margin}" y1="${y(9.75)}" x2="${width - margin}" y2="${y(9.75)}"/>
  </g>

  <g font-family="Times New Roman, serif" font-size="24" fill="#243742">
    <text x="${x(80) - 28}" y="${margin - 25}">80.0°E</text>
    <text x="${x(81) - 28}" y="${margin - 25}">81.0°E</text>
    <text x="${margin - 78}" y="${y(9.5) + 8}">9.5°N</text>
    <text x="${margin - 82}" y="${y(9.75) + 8}">9.75°N</text>
  </g>

  <polygon points="${points([
    [79.66, 9.48], [79.83, 9.55], [79.98, 9.58], [80.10, 9.55],
    [80.24, 9.50], [80.42, 9.47], [80.62, 9.44], [80.86, 9.40],
    [81.08, 9.35], [81.18, 9.29], [80.92, 9.31], [80.61, 9.35],
    [80.25, 9.38], [79.96, 9.39], [79.74, 9.42],
  ])}" fill="#cfe8c8" stroke="#658b63" stroke-width="3"/>

  <polygon points="${points([
    [79.62, 9.77], [79.73, 9.88], [79.93, 9.94], [80.23, 9.96],
    [80.51, 9.93], [80.82, 9.86], [81.08, 9.78], [81.17, 9.68],
    [81.04, 9.57], [80.77, 9.51], [80.45, 9.48], [80.18, 9.52],
    [79.93, 9.56], [79.72, 9.62],
  ])}" fill="#b9ddb2" stroke="#557d55" stroke-width="3"/>

  <polygon points="${points([
    [79.69, 9.64], [79.78, 9.68], [79.91, 9.69], [80.03, 9.67],
    [80.13, 9.62], [80.02, 9.60], [79.85, 9.59],
  ])}" fill="#9ecb99" stroke="#557d55" stroke-width="2"/>

  <rect x="${x(bounds.west)}" y="${y(bounds.north)}" width="${mapWidth}" height="${mapHeight}" fill="none" stroke="#9a3a3a" stroke-width="4" stroke-dasharray="16 10"/>

  <g>
    <rect x="${(sampleX - 18).toFixed(1)}" y="${(sampleY - 18).toFixed(1)}" width="36" height="36" fill="#ffffff" stroke="#d71920" stroke-width="6"/>
    <line x1="${sampleX.toFixed(1)}" y1="${(sampleY - 34).toFixed(1)}" x2="${sampleX.toFixed(1)}" y2="${(sampleY - 65).toFixed(1)}" stroke="#d71920" stroke-width="4"/>
    <rect x="${(sampleX + 30).toFixed(1)}" y="${(sampleY - 86).toFixed(1)}" width="310" height="76" rx="8" fill="#ffffff" stroke="#2f4f5f" stroke-width="2"/>
    <text x="${(sampleX + 48).toFixed(1)}" y="${(sampleY - 55).toFixed(1)}" font-family="Times New Roman, serif" font-size="24" font-weight="700" fill="#172d38">${sample.label}</text>
    <text x="${(sampleX + 48).toFixed(1)}" y="${(sampleY - 25).toFixed(1)}" font-family="Times New Roman, serif" font-size="22" fill="#172d38">9°40'01.6"N, 80°01'52.9"E</text>
  </g>

  <g font-family="Times New Roman, serif" fill="#20323b">
    <text x="${x(80.35)}" y="${y(9.82)}" font-size="30" font-weight="700">Jaffna Peninsula</text>
    <text x="${x(79.67)}" y="${y(9.34)}" font-size="28">Palk Strait</text>
    <text x="${x(79.77)}" y="${y(9.62)}" font-size="22">Velanai / Thurayoor</text>
  </g>

  <g transform="translate(${width - 190}, ${margin + 25})">
    <path d="M45 0 L75 95 L45 75 L15 95 Z" fill="#ffffff" stroke="#2f4f5f" stroke-width="4"/>
    <text x="37" y="128" font-family="Times New Roman, serif" font-size="24" fill="#20323b">N</text>
  </g>

  <g transform="translate(${margin + 25}, ${height - margin - 55})" font-family="Times New Roman, serif" fill="#20323b">
    <line x1="0" y1="0" x2="180" y2="0" stroke="#20323b" stroke-width="6"/>
    <line x1="0" y1="-12" x2="0" y2="12" stroke="#20323b" stroke-width="4"/>
    <line x1="180" y1="-12" x2="180" y2="12" stroke="#20323b" stroke-width="4"/>
    <text x="0" y="38" font-size="22">0</text>
    <text x="130" y="38" font-size="22">~50 km</text>
  </g>

  <g font-family="Times New Roman, serif" font-size="24" fill="#20323b">
    <rect x="${width - margin - 300}" y="${height - margin - 52}" width="28" height="28" fill="#ffffff" stroke="#d71920" stroke-width="5"/>
    <text x="${width - margin - 260}" y="${height - margin - 29}">Square marker: sample location</text>
  </g>
</svg>
`;

fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(outPath, svg);
console.log(`Generated ${outPath}`);
