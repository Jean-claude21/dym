// Pousse les variables de la Function « api » (spec 084) : `neon deploy` ne met pas à jour les
// variables d'une Function déjà créée. Usage, depuis functions/ :
//   node scripts/deploy-env.mjs <fichier .env hors dépôt> <branche> [<projet>]
// Le jeton Neon est lu dans NEON_API_KEY (environnement). Aucune valeur n'est affichée.
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { parseEnv } from 'node:util';

// Jamais par un shell : sous Windows, cmd.exe abîme les valeurs JSON (guillemets) et la Function
// ne démarre plus. On lance la CLI Neon directement avec Node.
function neonCli() {
  if (process.platform !== 'win32') return { cmd: 'npx', pre: ['-y', 'neonctl'] };
  const cache = path.join(process.env.LOCALAPPDATA ?? '', 'npm-cache', '_npx');
  for (const dir of fs.existsSync(cache) ? fs.readdirSync(cache) : []) {
    const cli = path.join(cache, dir, 'node_modules', 'neonctl', 'bin', 'cli.js');
    if (fs.existsSync(cli)) return { cmd: process.execPath, pre: [cli] };
  }
  console.error('neonctl introuvable : lancer une fois `npx -y neonctl --version`, puis recommencer.');
  process.exit(2);
}

const [file, branch, project = process.env.NEON_PROJECT_ID] = process.argv.slice(2);
if (!file || !branch || !project) {
  console.error('usage : node scripts/deploy-env.mjs <fichier .env> <branche> [<projet>]');
  process.exit(2);
}
const env = parseEnv(fs.readFileSync(file, 'utf8'));
const args = ['functions', 'deploy', 'api', '--project-id', project, '--branch', branch,
  '--src', 'src/index.ts', '--runtime', 'nodejs24'];
if (process.env.NEON_API_KEY) args.push('--api-key', process.env.NEON_API_KEY);
for (const [k, v] of Object.entries(env)) args.push('--env', `${k}=${v}`);
const cli = neonCli();
const r = spawnSync(cli.cmd, [...cli.pre, ...args], { encoding: 'utf8', shell: false, maxBuffer: 1 << 26 });
let out = `${r.stdout ?? ''}\n${r.stderr ?? ''}`;
for (const s of [...Object.values(env), process.env.NEON_API_KEY ?? '']) {
  if (s && s.length > 6) out = out.split(s).join('…');
}
console.log(out.split('\n').slice(-12).join('\n'));
console.log(Object.keys(env).length, 'variables poussées :', Object.keys(env).join(', '));
console.log('Vérifier ensuite la santé : GET <DYM_FUNCTIONS_URL>/health doit répondre 200.');
process.exit(r.status ?? 1);
