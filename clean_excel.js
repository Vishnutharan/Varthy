const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

const DESKTOP_DIR = process.env.VAR_DESKTOP_DIR || 'C:\\Users\\karun\\OneDrive\\Desktop\\Var';
const WORK_DIR = __dirname;
const INPUT_NAME = 'results analysis.xlsx';
const CLEAN_NAME = 'results_analysis_cleaned.xlsx';

function firstExisting(paths) {
  const found = paths.find((p) => fs.existsSync(p));
  if (!found) {
    throw new Error(`None of these paths exist: ${paths.join(', ')}`);
  }
  return found;
}

const inputPath = firstExisting([
  path.join(DESKTOP_DIR, INPUT_NAME),
  path.join(WORK_DIR, INPUT_NAME),
]);

const outputDirs = [DESKTOP_DIR, WORK_DIR].filter((dir, idx, arr) => fs.existsSync(dir) && arr.indexOf(dir) === idx);
const wb = XLSX.readFile(inputPath);

function rows(sheetName) {
  const sheet = wb.Sheets[sheetName];
  if (!sheet) throw new Error(`Missing sheet: ${sheetName}`);
  return XLSX.utils.sheet_to_json(sheet, { header: 1, defval: null, blankrows: false });
}

function isNum(value) {
  return typeof value === 'number' && Number.isFinite(value);
}

function cleanText(value) {
  return String(value || '').replace(/\s+/g, ' ').trim();
}

function round(value, digits = 3) {
  if (!Number.isFinite(value)) return null;
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}

function mean(values) {
  const nums = values.filter(isNum);
  return nums.reduce((sum, value) => sum + value, 0) / nums.length;
}

function sd(values) {
  const nums = values.filter(isNum);
  if (nums.length < 2) return 0;
  const avg = mean(nums);
  return Math.sqrt(nums.reduce((sum, value) => sum + (value - avg) ** 2, 0) / (nums.length - 1));
}

function sem(values) {
  const nums = values.filter(isNum);
  return sd(nums) / Math.sqrt(nums.length);
}

function groupBy(values, keyFn) {
  const grouped = new Map();
  for (const value of values) {
    const key = keyFn(value);
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key).push(value);
  }
  return grouped;
}

function betacf(a, b, x) {
  const maxIterations = 100;
  const eps = 3e-7;
  const fpmin = 1e-30;
  let qab = a + b;
  let qap = a + 1;
  let qam = a - 1;
  let c = 1;
  let d = 1 - (qab * x) / qap;
  if (Math.abs(d) < fpmin) d = fpmin;
  d = 1 / d;
  let h = d;

  for (let m = 1; m <= maxIterations; m += 1) {
    const m2 = 2 * m;
    let aa = (m * (b - m) * x) / ((qam + m2) * (a + m2));
    d = 1 + aa * d;
    if (Math.abs(d) < fpmin) d = fpmin;
    c = 1 + aa / c;
    if (Math.abs(c) < fpmin) c = fpmin;
    d = 1 / d;
    h *= d * c;
    aa = (-(a + m) * (qab + m) * x) / ((a + m2) * (qap + m2));
    d = 1 + aa * d;
    if (Math.abs(d) < fpmin) d = fpmin;
    c = 1 + aa / c;
    if (Math.abs(c) < fpmin) c = fpmin;
    d = 1 / d;
    const del = d * c;
    h *= del;
    if (Math.abs(del - 1) < eps) break;
  }
  return h;
}

function logGamma(z) {
  const coefficients = [
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];
  if (z < 0.5) {
    return Math.log(Math.PI) - Math.log(Math.sin(Math.PI * z)) - logGamma(1 - z);
  }
  z -= 1;
  let x = 0.99999999999980993;
  for (let i = 0; i < coefficients.length; i += 1) {
    x += coefficients[i] / (z + i + 1);
  }
  const t = z + coefficients.length - 0.5;
  return 0.9189385332046727 + (z + 0.5) * Math.log(t) - t + Math.log(x);
}

function betaIncomplete(x, a, b) {
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  const bt = Math.exp(logGamma(a + b) - logGamma(a) - logGamma(b) + a * Math.log(x) + b * Math.log(1 - x));
  if (x < (a + 1) / (a + b + 2)) return (bt * betacf(a, b, x)) / a;
  return 1 - (bt * betacf(b, a, 1 - x)) / b;
}

function tCdf(t, df) {
  const x = df / (df + t * t);
  const ib = betaIncomplete(x, df / 2, 0.5);
  return t >= 0 ? 1 - ib / 2 : ib / 2;
}

function fCdf(f, df1, df2) {
  if (f <= 0) return 0;
  return betaIncomplete((df1 * f) / (df1 * f + df2), df1 / 2, df2 / 2);
}

function welch(valuesA, valuesB) {
  const n1 = valuesA.length;
  const n2 = valuesB.length;
  const m1 = mean(valuesA);
  const m2 = mean(valuesB);
  const s1 = sd(valuesA);
  const s2 = sd(valuesB);
  const se2 = (s1 ** 2) / n1 + (s2 ** 2) / n2;
  const t = (m1 - m2) / Math.sqrt(se2);
  const df = (se2 ** 2) / (((s1 ** 2 / n1) ** 2) / (n1 - 1) + ((s2 ** 2 / n2) ** 2) / (n2 - 1));
  const p = 2 * (1 - tCdf(Math.abs(t), df));
  return { t, df, p };
}

function oneWayAnova(groups) {
  const labels = Object.keys(groups);
  const all = labels.flatMap((label) => groups[label]);
  const grandMean = mean(all);
  const ssBetween = labels.reduce((sum, label) => sum + groups[label].length * (mean(groups[label]) - grandMean) ** 2, 0);
  const ssWithin = labels.reduce((sum, label) => {
    const avg = mean(groups[label]);
    return sum + groups[label].reduce((inner, value) => inner + (value - avg) ** 2, 0);
  }, 0);
  const dfBetween = labels.length - 1;
  const dfWithin = all.length - labels.length;
  const msBetween = ssBetween / dfBetween;
  const msWithin = ssWithin / dfWithin;
  const f = msBetween / msWithin;
  const p = 1 - fCdf(f, dfBetween, dfWithin);
  return { dfBetween, dfWithin, ssBetween, ssWithin, msBetween, msWithin, f, p };
}

function jarqueBera(values) {
  const nums = values.filter(isNum);
  const avg = mean(nums);
  const s = sd(nums);
  const n = nums.length;
  const skew = nums.reduce((sum, value) => sum + ((value - avg) / s) ** 3, 0) / n;
  const kurtosis = nums.reduce((sum, value) => sum + ((value - avg) / s) ** 4, 0) / n;
  const jb = (n / 6) * (skew ** 2 + ((kurtosis - 3) ** 2) / 4);
  const p = Math.exp(-jb / 2);
  return { statistic: jb, p, skew, kurtosis };
}

function extractSeaCucumber() {
  const data = rows('sea cucumber growth ');
  const blockStarts = [];
  for (let r = 0; r < data.length; r += 1) {
    const cell = data[r][0];
    if (typeof cell === 'string' && /^week\s+\d+/i.test(cell.trim())) {
      blockStarts.push({ row: r, label: cell.trim() });
    }
  }
  blockStarts.push({ row: data.length, label: 'END' });

  const raw = [];
  for (let i = 0; i < blockStarts.length - 1; i += 1) {
    const start = blockStarts[i].row;
    const end = blockStarts[i + 1].row;
    const sampleWeek = Number(blockStarts[i].label.match(/\d+/)[0]);
    const analysisWeek = i + 1;
    const date = cleanText(data[start][1]);
    let headerRow = -1;
    let columns = [];
    for (let r = start; r < Math.min(start + 8, end); r += 1) {
      columns = [];
      for (let c = 0; c < data[r].length; c += 1) {
        if (cleanText(data[r][c]).toLowerCase() === 'sea cucumber') columns.push(c);
      }
      if (columns.length >= 2) {
        headerRow = r;
        break;
      }
    }
    if (headerRow < 0) continue;
    const treatments = [
      { name: 'IMTA', col: columns[0] },
      { name: 'Monoculture', col: columns[1] },
    ];
    for (let r = headerRow + 1; r < end; r += 1) {
      for (const treatment of treatments) {
        const id = data[r][treatment.col];
        const weight = data[r][treatment.col + 1];
        const length = data[r][treatment.col + 2];
        if (isNum(id) && isNum(weight) && isNum(length)) {
          raw.push({
            AnalysisWeek: analysisWeek,
            SampleWeek: sampleWeek,
            Date: date,
            Treatment: treatment.name,
            Individual: id,
            Weight_g: weight,
            Length_cm: length,
          });
        }
      }
    }
  }

  const summary = [];
  for (const [key, records] of groupBy(raw, (record) => `${record.AnalysisWeek}|${record.SampleWeek}|${record.Treatment}`)) {
    const [analysisWeek, sampleWeek, treatment] = key.split('|');
    const weights = records.map((record) => record.Weight_g);
    const lengths = records.map((record) => record.Length_cm);
    summary.push({
      AnalysisWeek: Number(analysisWeek),
      SampleWeek: Number(sampleWeek),
      Treatment: treatment,
      n: records.length,
      Mean_Weight_g: round(mean(weights), 3),
      SD_Weight_g: round(sd(weights), 3),
      Mean_Length_cm: round(mean(lengths), 3),
      SD_Length_cm: round(sd(lengths), 3),
    });
  }
  summary.sort((a, b) => a.Treatment.localeCompare(b.Treatment) || a.AnalysisWeek - b.AnalysisWeek);

  for (const row of summary) {
    const prev = summary.find((candidate) => candidate.Treatment === row.Treatment && candidate.AnalysisWeek === row.AnalysisWeek - 1);
    if (prev) {
      row.Weight_Change_g = round(row.Mean_Weight_g - prev.Mean_Weight_g, 3);
      row.AGR_g_per_day = round((row.Mean_Weight_g - prev.Mean_Weight_g) / 7, 3);
      row.SGR_percent_per_day = round((Math.log(row.Mean_Weight_g) - Math.log(prev.Mean_Weight_g)) * 100 / 7, 3);
    }
  }

  return { raw, summary };
}

function extractSeaweed() {
  const data = rows('sea weed growth ');
  const raw = [];
  const replicateColumns = [
    { replicate: 'Replicate 1', col: 0 },
    { replicate: 'Replicate 2', col: 7 },
    { replicate: 'Replicate 3', col: 14 },
  ];
  for (const rep of replicateColumns) {
    for (let r = 2; r < data.length; r += 1) {
      const seedling = cleanText(data[r][rep.col]);
      const initial = data[r][rep.col + 1];
      const final = data[r][rep.col + 4];
      if (/^r\d+\s+s\d+$/i.test(seedling) && isNum(initial) && isNum(final)) {
        raw.push({
          Replicate: rep.replicate,
          Seedling: seedling,
          Initial_Weight_g: initial,
          Final_Weight_g: final,
          Weight_Gain_g: round(final - initial, 3),
          Survived: final > 0,
        });
      }
    }
  }
  const summary = [];
  for (const [replicate, records] of groupBy(raw, (record) => record.Replicate)) {
    const gains = records.map((record) => record.Weight_Gain_g);
    const initial = records.reduce((sum, record) => sum + record.Initial_Weight_g, 0);
    const final = records.reduce((sum, record) => sum + record.Final_Weight_g, 0);
    summary.push({
      Replicate: replicate,
      n: records.length,
      Initial_Total_g: round(initial, 3),
      Final_Total_g: round(final, 3),
      Biomass_Gain_g: round(final - initial, 3),
      Percent_Gain: round(((final - initial) / initial) * 100, 2),
      Survival_Percent: round((records.filter((record) => record.Survived).length / records.length) * 100, 2),
      Mean_Weight_Gain_g: round(mean(gains), 3),
      SD_Weight_Gain_g: round(sd(gains), 3),
      SE_Weight_Gain_g: round(sem(gains), 3),
    });
  }
  summary.sort((a, b) => a.Replicate.localeCompare(b.Replicate));
  const overallInitial = summary.reduce((sum, record) => sum + record.Initial_Total_g, 0);
  const overallFinal = summary.reduce((sum, record) => sum + record.Final_Total_g, 0);
  summary.push({
    Replicate: 'Overall',
    n: raw.length,
    Initial_Total_g: round(overallInitial, 3),
    Final_Total_g: round(overallFinal, 3),
    Biomass_Gain_g: round(overallFinal - overallInitial, 3),
    Percent_Gain: round(((overallFinal - overallInitial) / overallInitial) * 100, 2),
    Survival_Percent: round((raw.filter((record) => record.Survived).length / raw.length) * 100, 2),
    Mean_Weight_Gain_g: round(mean(raw.map((record) => record.Weight_Gain_g)), 3),
    SD_Weight_Gain_g: round(sd(raw.map((record) => record.Weight_Gain_g)), 3),
    SE_Weight_Gain_g: round(sem(raw.map((record) => record.Weight_Gain_g)), 3),
  });
  return { raw, summary };
}

function extractWaterQuality() {
  const data = rows('water quality ');
  const blockStarts = [];
  for (let r = 0; r < data.length; r += 1) {
    if (/^week\s+\d+/i.test(cleanText(data[r][0]))) blockStarts.push({ row: r, label: cleanText(data[r][0]) });
  }
  blockStarts.push({ row: data.length, label: 'END' });
  const parameterNames = ['pH', 'TDS_ppt', 'Salinity_ppt', 'Temperature_C', 'DO_mg_L', 'Conductivity_mS_cm'];
  const quality = [];
  const nutrients = [];

  for (let i = 0; i < blockStarts.length - 1; i += 1) {
    const start = blockStarts[i].row;
    const end = blockStarts[i + 1].row;
    const sampleWeek = Number(blockStarts[i].label.match(/\d+/)[0]);
    const treatmentMeans = [];
    const nutrientMeans = [];
    for (let r = start; r < end; r += 1) {
      if (cleanText(data[r][0]).toLowerCase() === 'mean' && parameterNames.every((_, idx) => isNum(data[r][idx + 1]))) {
        treatmentMeans.push(data[r].slice(1, 7));
      }
      if (cleanText(data[r][9]).toLowerCase() === 'mean' && [10, 11, 12, 13, 14, 15].every((idx) => isNum(data[r][idx]))) {
        nutrientMeans.push(data[r].slice(10, 16));
      }
    }
    ['IMTA', 'Monoculture'].forEach((treatment, idx) => {
      if (treatmentMeans[idx]) {
        const row = { SampleWeek: sampleWeek, Treatment: treatment };
        parameterNames.forEach((parameter, pidx) => { row[parameter] = round(treatmentMeans[idx][pidx], 3); });
        quality.push(row);
      }
      if (nutrientMeans[idx]) {
        const [NO2, NaNO2, NO2_N, P2O5, P, PO4] = nutrientMeans[idx];
        nutrients.push({
          SampleWeek: sampleWeek,
          Treatment: treatment,
          NO2_ug_L: round(NO2, 3),
          NaNO2_ug_L: round(NaNO2, 3),
          NO2_N_ug_L: round(NO2_N, 3),
          P2O5_ug_L: round(P2O5, 3),
          P_ug_L: round(P, 3),
          PO4_ug_L: round(PO4, 3),
        });
      }
    });
  }
  return { quality, nutrients };
}

function tableRows(sheetName) {
  return rows(sheetName).map((row) => {
    const obj = {};
    row.forEach((value, idx) => { obj[`Column_${idx + 1}`] = value; });
    return obj;
  });
}

const seaCucumber = extractSeaCucumber();
const seaweed = extractSeaweed();
const water = extractWaterQuality();
const soil = tableRows('Soil organic content ');
const proximate = tableRows('proximate analysis seaweed');

const imtaWeights = seaCucumber.raw.filter((r) => r.Treatment === 'IMTA').map((r) => r.Weight_g);
const monoWeights = seaCucumber.raw.filter((r) => r.Treatment === 'Monoculture').map((r) => r.Weight_g);
const imtaLengths = seaCucumber.raw.filter((r) => r.Treatment === 'IMTA').map((r) => r.Length_cm);
const monoLengths = seaCucumber.raw.filter((r) => r.Treatment === 'Monoculture').map((r) => r.Length_cm);
const weightTest = welch(imtaWeights, monoWeights);
const lengthTest = welch(imtaLengths, monoLengths);
const seaweedGroups = {};
for (const record of seaweed.raw) {
  if (!seaweedGroups[record.Replicate]) seaweedGroups[record.Replicate] = [];
  seaweedGroups[record.Replicate].push(record.Weight_Gain_g);
}
const seaweedAnova = oneWayAnova(seaweedGroups);

const summary = {
  generatedBy: 'clean_excel.js',
  sourceWorkbook: inputPath,
  seaCucumber: {
    rawCount: seaCucumber.raw.length,
    descriptive: [
      { Parameter: 'Body Weight (g)', Treatment: 'IMTA', n: imtaWeights.length, Mean: round(mean(imtaWeights), 3), SD: round(sd(imtaWeights), 3), t: round(weightTest.t, 4), df: round(weightTest.df, 3), p: round(weightTest.p, 4) },
      { Parameter: 'Body Weight (g)', Treatment: 'Monoculture', n: monoWeights.length, Mean: round(mean(monoWeights), 3), SD: round(sd(monoWeights), 3), t: null, df: null, p: null },
      { Parameter: 'Body Length (cm)', Treatment: 'IMTA', n: imtaLengths.length, Mean: round(mean(imtaLengths), 3), SD: round(sd(imtaLengths), 3), t: round(lengthTest.t, 4), df: round(lengthTest.df, 3), p: round(lengthTest.p, 4) },
      { Parameter: 'Body Length (cm)', Treatment: 'Monoculture', n: monoLengths.length, Mean: round(mean(monoLengths), 3), SD: round(sd(monoLengths), 3), t: null, df: null, p: null },
    ],
    weeklySummary: seaCucumber.summary,
    normalityScreening: [
      { Parameter: 'Body Weight', Treatment: 'IMTA', Method: 'Jarque-Bera', Statistic: round(jarqueBera(imtaWeights).statistic, 4), p: round(jarqueBera(imtaWeights).p, 4) },
      { Parameter: 'Body Weight', Treatment: 'Monoculture', Method: 'Jarque-Bera', Statistic: round(jarqueBera(monoWeights).statistic, 4), p: round(jarqueBera(monoWeights).p, 4) },
      { Parameter: 'Body Length', Treatment: 'IMTA', Method: 'Jarque-Bera', Statistic: round(jarqueBera(imtaLengths).statistic, 4), p: round(jarqueBera(imtaLengths).p, 4) },
      { Parameter: 'Body Length', Treatment: 'Monoculture', Method: 'Jarque-Bera', Statistic: round(jarqueBera(monoLengths).statistic, 4), p: round(jarqueBera(monoLengths).p, 4) },
    ],
  },
  seaweed: {
    rawCount: seaweed.raw.length,
    summary: seaweed.summary,
    anova: {
      dfBetween: seaweedAnova.dfBetween,
      dfWithin: seaweedAnova.dfWithin,
      ssBetween: round(seaweedAnova.ssBetween, 3),
      ssWithin: round(seaweedAnova.ssWithin, 3),
      msBetween: round(seaweedAnova.msBetween, 3),
      msWithin: round(seaweedAnova.msWithin, 3),
      f: round(seaweedAnova.f, 4),
      p: round(seaweedAnova.p, 4),
    },
  },
  waterQuality: water.quality,
  nutrients: water.nutrients,
};

const cleanWorkbook = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(cleanWorkbook, XLSX.utils.json_to_sheet(seaCucumber.summary), 'Sea Cucumber Summary');
XLSX.utils.book_append_sheet(cleanWorkbook, XLSX.utils.json_to_sheet(seaCucumber.raw), 'Sea Cucumber Raw');
XLSX.utils.book_append_sheet(cleanWorkbook, XLSX.utils.json_to_sheet(seaweed.summary), 'Seaweed Summary');
XLSX.utils.book_append_sheet(cleanWorkbook, XLSX.utils.json_to_sheet(seaweed.raw), 'Seaweed Raw');
XLSX.utils.book_append_sheet(cleanWorkbook, XLSX.utils.json_to_sheet(water.quality), 'Water Quality Summary');
XLSX.utils.book_append_sheet(cleanWorkbook, XLSX.utils.json_to_sheet(water.nutrients), 'Nutrient Summary');
XLSX.utils.book_append_sheet(cleanWorkbook, XLSX.utils.json_to_sheet(soil), 'Soil Organic Content');
XLSX.utils.book_append_sheet(cleanWorkbook, XLSX.utils.json_to_sheet(proximate), 'Proximate Seaweed');

function writeTextReport(outDir) {
  const output = [];
  output.push('COMPREHENSIVE STATISTICAL ANALYSIS - IMTA vs MONOCULTURE');
  output.push(`Source workbook: ${inputPath}`);
  output.push('');
  output.push('SECTION 1: SEA CUCUMBER GROWTH ANALYSIS');
  output.push('Weekly mean summaries with dynamically computed AGR and SGR:');
  for (const row of seaCucumber.summary) {
    output.push(`${row.Treatment} Week ${row.AnalysisWeek} (sample week ${row.SampleWeek}): n=${row.n}, weight=${row.Mean_Weight_g} +/- ${row.SD_Weight_g} g, length=${row.Mean_Length_cm} +/- ${row.SD_Length_cm} cm, AGR=${row.AGR_g_per_day ?? 'NA'}, SGR=${row.SGR_percent_per_day ?? 'NA'}`);
  }
  output.push('');
  output.push('Welch tests using raw individual observations:');
  output.push(`Body weight: t=${round(weightTest.t, 4)}, df=${round(weightTest.df, 3)}, p=${round(weightTest.p, 4)}, IMTA mean=${round(mean(imtaWeights), 3)}, Monoculture mean=${round(mean(monoWeights), 3)}`);
  output.push(`Body length: t=${round(lengthTest.t, 4)}, df=${round(lengthTest.df, 3)}, p=${round(lengthTest.p, 4)}, IMTA mean=${round(mean(imtaLengths), 3)}, Monoculture mean=${round(mean(monoLengths), 3)}`);
  output.push('');
  output.push('SECTION 2: SEAWEED BIOMASS ANALYSIS');
  for (const row of seaweed.summary) {
    output.push(`${row.Replicate}: n=${row.n}, initial=${row.Initial_Total_g} g, final=${row.Final_Total_g} g, gain=${row.Biomass_Gain_g} g, survival=${row.Survival_Percent}%, mean gain=${row.Mean_Weight_Gain_g} +/- ${row.SD_Weight_Gain_g} g`);
  }
  output.push(`ANOVA weight gain across replicates: F=${summary.seaweed.anova.f}, p=${summary.seaweed.anova.p}`);
  output.push('');
  output.push('SECTION 3: WATER QUALITY SUMMARY');
  for (const row of water.quality) {
    output.push(`${row.Treatment} Week ${row.SampleWeek}: pH=${row.pH}, TDS=${row.TDS_ppt}, salinity=${row.Salinity_ppt}, temp=${row.Temperature_C}, DO=${row.DO_mg_L}, conductivity=${row.Conductivity_mS_cm}`);
  }
  output.push('');
  output.push('SECTION 4: NUTRIENT SUMMARY');
  for (const row of water.nutrients) {
    output.push(`${row.Treatment} Week ${row.SampleWeek}: NO2=${row.NO2_ug_L}, NaNO2=${row.NaNO2_ug_L}, NO2-N=${row.NO2_N_ug_L}, P2O5=${row.P2O5_ug_L}, P=${row.P_ug_L}, PO4=${row.PO4_ug_L}`);
  }
  output.push('');
  output.push('KEY CORRECTION: Phosphorus and phosphate increased in the IMTA treatment between Week 3 and Week 7, while they decreased in Monoculture. The current IMTA ratio therefore cannot be described as superior for phosphate removal.');
  output.push('ANALYSIS COMPLETE - deterministic outputs generated from workbook values only.');

  const rOut = path.join(outDir, 'R_output');
  fs.mkdirSync(rOut, { recursive: true });
  fs.writeFileSync(path.join(rOut, 'analysis_results.txt'), `${output.join('\n')}\n`);
}

for (const outDir of outputDirs) {
  XLSX.writeFile(cleanWorkbook, path.join(outDir, CLEAN_NAME));
  fs.writeFileSync(path.join(outDir, 'analysis_summary.json'), `${JSON.stringify(summary, null, 2)}\n`);
  writeTextReport(outDir);
}

console.log(`Cleaned workbook and analysis summary generated from ${inputPath}`);
for (const outDir of outputDirs) {
  console.log(`- ${path.join(outDir, CLEAN_NAME)}`);
  console.log(`- ${path.join(outDir, 'analysis_summary.json')}`);
  console.log(`- ${path.join(outDir, 'R_output', 'analysis_results.txt')}`);
}
