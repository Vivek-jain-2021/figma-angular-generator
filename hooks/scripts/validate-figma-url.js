#!/usr/bin/env node
/**
 * PreToolUse hook — validates Figma URL format before fetching design context.
 * Reads tool input from stdin, exits non-zero to block if invalid.
 */

let input = '';
process.stdin.on('data', chunk => (input += chunk));
process.stdin.on('end', () => {
  try {
    const { tool_input } = JSON.parse(input);
    const { fileKey, nodeId } = tool_input ?? {};

    if (!fileKey || typeof fileKey !== 'string' || fileKey.trim() === '') {
      console.error('[figma-angular-generator] Missing or invalid fileKey.');
      process.exit(1);
    }

    if (!nodeId || !/^\d+[:-]\d+$/.test(nodeId)) {
      console.error(
        `[figma-angular-generator] Invalid nodeId "${nodeId}". Expected format: "123:456" or "123-456".`
      );
      process.exit(1);
    }

    process.exit(0);
  } catch {
    // Non-JSON input — allow through
    process.exit(0);
  }
});
