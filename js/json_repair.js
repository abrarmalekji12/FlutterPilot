// json_repair_runner.js
import { jsonrepair } from 'jsonrepair';
import readline from 'readline';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
});

rl.on('line', (line) => {
  try {
    const fixed = jsonrepair(line);
    console.log(fixed);
  } catch (err) {
    console.error('ERROR:', err.message);
  }
});