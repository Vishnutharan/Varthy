const XLSX = require('xlsx');
const path = require('path');

const dataPath = path.join('C:\\Users\\karun\\OneDrive\\Desktop\\Var', 'data sheet.xlsx');
const wb1 = XLSX.readFile(dataPath);
console.log("Sheet names:", wb1.SheetNames);
wb1.SheetNames.forEach(name => {
    const ws = wb1.Sheets[name];
    const data = XLSX.utils.sheet_to_json(ws, { header: 1 });
    console.log(`\n--- Sheet: ${name} ---`);
    console.log(`Rows: ${data.length}`);
    data.forEach((row, i) => console.log(`Row ${i}: ${JSON.stringify(row)}`));
});
