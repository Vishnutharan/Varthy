const XLSX = require('xlsx');
const path = require('path');
const fs = require('fs');

const dataPath = path.join('C:\\Users\\karun\\OneDrive\\Desktop\\Var', 'data sheet.xlsx');
const resultsPath = path.join('C:\\Users\\karun\\OneDrive\\Desktop\\Var', 'results analysis.xlsx');
const wb1 = XLSX.readFile(dataPath);
const wb2 = XLSX.readFile(resultsPath);

const outDir = 'd:\\Varthy\\csv_data';
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

// Export all sheets as CSV
function exportWorkbook(wb, prefix) {
    wb.SheetNames.forEach(name => {
        const ws = wb.Sheets[name];
        const csv = XLSX.utils.sheet_to_csv(ws);
        const safeName = name.replace(/[^a-zA-Z0-9]/g, '_').replace(/_+/g, '_');
        const fname = `${prefix}_${safeName}.csv`;
        fs.writeFileSync(path.join(outDir, fname), csv);
        console.log(`Saved: ${fname}`);
    });
}

exportWorkbook(wb1, 'data');
exportWorkbook(wb2, 'results');

console.log("\nAll CSV files exported!");
