#!/usr/bin/env node

var fs = require('fs')
var path = require('path')

if (process.argv.length != 3 || !process.argv[2].includes('index.json')) {
  console.error(`
    usage: INDEX_JSON

    Produces an {"art": [...]} JSON array of files beside INDEX_JSON.
  `);
  process.exit(1);
}

const index = process.argv[2];

var files = fs.readdirSync(path.dirname(index));
fs.writeFileSync(index, JSON.stringify({art: files}));
