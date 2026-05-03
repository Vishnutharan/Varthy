const mammoth = require('mammoth');
const path = require('path');
const fs = require('fs');

async function readDoc() {
    const docPath = path.join('C:\\Users\\karun\\OneDrive\\Desktop\\Var', 'result.docx');
    const result = await mammoth.extractRawText({ path: docPath });
    fs.writeFileSync('d:\\Varthy\\doc_content.txt', result.value);
    console.log("Document saved. Total chars:", result.value.length);
}

readDoc().catch(console.error);
