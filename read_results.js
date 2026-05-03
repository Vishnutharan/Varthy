const XLSX = require('xlsx');
const path = require('path');

// Read results analysis fully
const resultsPath = path.join('C:\\Users\\karun\\OneDrive\\Desktop\\Var', 'results analysis.xlsx');
const wb2 = XLSX.readFile(resultsPath);
console.log("=== RESULTS ANALYSIS ===");
console.log("Sheet names:", wb2.SheetNames);
wb2.SheetNames.forEach(name => {
    const ws = wb2.Sheets[name];
    const data = XLSX.utils.sheet_to_json(ws, { header: 1 });
    console.log(`\n--- Sheet: ${name} ---`);
    console.log(`Rows: ${data.length}`);
    data.forEach((row, i) => console.log(`Row ${i}: ${JSON.stringify(row)}`));
});
