// IO adapter only. All validation, statistics and report generation run in MoonBit.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const limit = 1048576;
const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const built = path.join(root, '_build/js/release/build/cmd/protocol/protocol.js');
try {
  if (process.argv.length > 3) throw new Error('usage: node tools/synthesis.mjs [request.json]');
  const input = process.argv[2];
  const descriptor = input ? fs.openSync(input, 'r') : 0;
  const chunks = [];
  let total = 0;
  try {
    while (true) {
      const chunk = Buffer.alloc(Math.min(65536, limit + 1 - total));
      const read = fs.readSync(descriptor, chunk, 0, chunk.length, null);
      if (!read) break;
      total += read;
      if (total > limit) throw new Error('input exceeds 1048576 bytes');
      chunks.push(chunk.subarray(0, read));
    }
  } finally {
    if (input) fs.closeSync(descriptor);
  }
  const text = new TextDecoder('utf-8', { fatal: true }).decode(Buffer.concat(chunks));
  if (!fs.existsSync(built)) throw new Error('run moon build --target js --release first');
  process.argv = [process.execPath, built, text];
  await import(pathToFileURL(built));
} catch (error) {
  process.stderr.write(`moonsynthesis: ${error.message}\n`);
  process.exitCode = 2;
}
