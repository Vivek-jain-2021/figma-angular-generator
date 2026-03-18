#!/usr/bin/env node
/**
 * PostToolUse hook — logs Angular component files written by the generator.
 * Only fires for files inside src/app/ to avoid noise from other writes.
 */

let input = '';
process.stdin.on('data', chunk => (input += chunk));
process.stdin.on('end', () => {
  try {
    const { tool_input } = JSON.parse(input);
    const filePath = tool_input?.file_path ?? '';

    const isAngularFile =
      filePath.includes('src/app/') || filePath.includes('src\\app\\');

    if (isAngularFile) {
      const fileName = filePath.split(/[\\/]/).pop();
      const isTs = fileName.endsWith('.component.ts');
      const isHtml = fileName.endsWith('.component.html');
      const isScss = fileName.endsWith('.component.scss');

      if (isTs || isHtml || isScss) {
        console.log(`[figma-angular-generator] Generated: ${filePath}`);
      }
    }
  } catch {
    // Ignore parse errors
  }
  process.exit(0);
});
