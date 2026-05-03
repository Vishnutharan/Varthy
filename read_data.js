const XLSX = require('xlsx');
const path = require('path');

// Read data sheet
const dataPath = path.join('C:\\Users\\karun\\OneDrive\\Desktop\\Var', 'data sheet.xlsx');
const wb1 = XLSX.readFile(dataPath);
console.log("=== DATA SHEET ===");
console.log("Sheet names:", wb1.SheetNames);
wb1.SheetNames.forEach(name => {
    const ws = wb1.Sheets[name];
    const data = XLSX.utils.sheet_to_json(ws, { header: 1 });
    console.log(`\n--- Sheet: ${name} ---`);
    console.log(`Rows: ${data.length}`);
    // Print first 30 rows
    data.slice(0, 30).forEach((row, i) => console.log(`Row ${i}: ${JSON.stringify(row)}`));
    if (data.length > 30) console.log(`... (${data.length - 30} more rows)`);
});

// Read results analysis
const resultsPath = path.join('C:\\Users\\karun\\OneDrive\\Desktop\\Var', 'results analysis.xlsx');
const wb2 = XLSX.readFile(resultsPath);
console.log("\n\n=== RESULTS ANALYSIS ===");
console.log("Sheet names:", wb2.SheetNames);
wb2.SheetNames.forEach(name => {
    const ws = wb2.Sheets[name];
    const data = XLSX.utils.sheet_to_json(ws, { header: 1 });
    console.log(`\n--- Sheet: ${name} ---`);
    console.log(`Rows: ${data.length}`);
    data.slice(0, 30).forEach((row, i) => console.log(`Row ${i}: ${JSON.stringify(row)}`));
    if (data.length > 30) console.log(`... (${data.length - 30} more rows)`);
});
