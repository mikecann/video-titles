import { expect, test } from 'bun:test';
import { cpSync, existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const repo = join(import.meta.dirname, '..');

test('standalone CLI loads its own .env from another working directory and saves chat', () => {
  const temp = mkdtempSync(join(tmpdir(), 'video-titles-'));
  try {
    // A parent key catches the old two-level lookup without using real credentials.
    const clone = join(temp, 'nested', 'clone');
    mkdirSync(clone, { recursive: true });
    cpSync(join(repo, 'index.ts'), join(clone, 'index.ts'));
    cpSync(join(repo, 'lib'), join(clone, 'lib'), { recursive: true });
    symlinkSync(join(repo, 'node_modules'), join(clone, 'node_modules'), 'junction');
    writeFileSync(join(temp, '.env'), 'OPENROUTER_API_KEY=wrong-parent-key\n');
    writeFileSync(join(clone, '.env'), 'OPENROUTER_API_KEY=test-local-key\n');
    const video = join(temp, 'clip with spaces.mp4');
    writeFileSync(video, '');
    writeFileSync(join(temp, 'clip with spaces.srt'), '1\r\n00:00:00,000 --> 00:00:01,000\r\nBuilding a backend\r\n');
    const requestFile = join(temp, 'request.json');
    const preload = join(clone, 'mock.ts');
    writeFileSync(preload, `
      import { mock } from 'bun:test';
      mock.module('@inquirer/prompts', () => ({
        confirm: async () => { throw new Error('Transcript was not found'); },
        input: async () => 'quit',
      }));
      globalThis.fetch = async (url, options) => {
        await Bun.write(${JSON.stringify(requestFile)}, JSON.stringify({ url, ...options }));
        return Response.json({ choices: [{ message: { content: '1. Build Your Own Backend' } }] });
      };
    `);
    const env = { ...process.env };
    delete env.OPENROUTER_API_KEY;
    const result = Bun.spawnSync([process.execPath, '--no-env-file', '--preload', preload, join(clone, 'index.ts'), video], {
      cwd: temp, env,
    });
    expect(result.exitCode).toBe(0);
    const request = JSON.parse(readFileSync(requestFile, 'utf8'));
    expect(request.headers.Authorization).toBe('Bearer test-local-key');
    expect(request.headers['HTTP-Referer']).toBe('https://github.com/mikecann/video-titles');
    expect(request.headers['X-Title']).toBe('video-titles');
    expect(JSON.parse(request.body).messages[1].content).toContain('Building a backend');
    expect(readFileSync(join(temp, 'clip with spaces-titles.txt'), 'utf8')).toContain('1. Build Your Own Backend');

    // A second launch should resume the log rather than repeat the opening request.
    rmSync(requestFile);
    const resumed = Bun.spawnSync([process.execPath, '--no-env-file', '--preload', preload, join(clone, 'index.ts'), video], { cwd: temp, env });
    expect(resumed.exitCode).toBe(0);
    expect(resumed.stdout.toString()).toContain('Resumed: 1 previous exchange(s) loaded.');
    expect(existsSync(requestFile)).toBe(false);

    rmSync(join(clone, '.env'));
    const missingKey = Bun.spawnSync([process.execPath, '--no-env-file', join(clone, 'index.ts'), video], { cwd: temp, env });
    expect(missingKey.exitCode).toBe(1);
    expect(missingKey.stderr.toString()).toContain('OPENROUTER_API_KEY is not set');
  } finally {
    rmSync(temp, { recursive: true, force: true });
  }
});

test('macOS installer links the live launcher and forwards a path with spaces', () => {
  if (process.platform === 'win32') return;
  const temp = mkdtempSync(join(tmpdir(), 'video-titles-install-'));
  try {
    const target = join(temp, 'bin with spaces');
    const installed = Bun.spawnSync(['bash', join(repo, 'install.sh'), target, '--skip-deps']);
    expect(installed.exitCode).toBe(0);
    const launched = Bun.spawnSync([join(target, 'video-titles'), join(temp, 'missing video.mp4')], {
      cwd: temp, env: { ...process.env, OPENROUTER_API_KEY: 'test-only' },
    });
    expect(launched.exitCode).toBe(1);
    expect(launched.stderr.toString()).toContain(`File not found: ${join(temp, 'missing video.mp4')}`);
  } finally {
    rmSync(temp, { recursive: true, force: true });
  }
});
