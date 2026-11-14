// Secrets DYM depuis Doppler (décision 0021). Aucune valeur n'est affichée.
//
//   DOPPLER_TOKEN=… node scripts/secrets.mjs functions-env <config> <fichier>
//       écrit le fichier d'environnement des Functions (projet dym-functions, config stg ou prd)
//   DOPPLER_TOKEN=… node scripts/secrets.mjs apps <config> <dossier des clés>
//       écrit les clés de signature Android dans <dossier des clés> (hors dépôt), les
//       `android/key.properties` et `android/app/google-services.json` des trois apps.
//
// Le jeton se lit dans DOPPLER_TOKEN (jamais en argument).
import fs from 'node:fs';
import path from 'node:path';

const [cmd, config, target] = process.argv.slice(2);
const token = process.env.DOPPLER_TOKEN;
if (!token || !cmd || !config || !target) {
  console.error('usage : DOPPLER_TOKEN=… node scripts/secrets.mjs functions-env|apps <config> <cible>');
  process.exit(2);
}

async function download(project) {
  const url = `https://api.doppler.com/v3/configs/config/secrets/download?project=${project}&config=${config}&format=json`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) throw new Error(`Doppler ${project}/${config} : ${res.status}`);
  const all = await res.json();
  // Variables techniques ajoutées par Doppler.
  for (const k of Object.keys(all)) if (k.startsWith('DOPPLER_')) delete all[k];
  return all;
}

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/(\w:)/, '$1')), '..');

if (cmd === 'functions-env') {
  const env = await download('dym-functions');
  const lines = Object.entries(env).map(([k, v]) => `${k}=${String(v).replace(/\r?\n/g, '')}`);
  fs.writeFileSync(target, `${lines.join('\n')}\n`, { mode: 0o600 });
  console.log(Object.keys(env).length, 'variables écrites :', Object.keys(env).join(', '));
} else if (cmd === 'apps') {
  const s = await download('dym-apps');
  fs.mkdirSync(target, { recursive: true });
  for (const [K, app] of [['CLIENT', 'dym_client'], ['VENDOR', 'dym_vendor'], ['DELIVERY', 'dym_delivery']]) {
    const androidDir = path.join(root, 'apps', app, 'android');
    if (s[`ANDROID_UPLOAD_KEYSTORE_B64_${K}`]) {
      const jks = path.join(target, `${app}-upload.jks`);
      fs.writeFileSync(jks, Buffer.from(s[`ANDROID_UPLOAD_KEYSTORE_B64_${K}`], 'base64'), { mode: 0o600 });
      const pass = s[`ANDROID_KEYSTORE_PASSWORD_${K}`];
      fs.writeFileSync(
        path.join(androidDir, 'key.properties'),
        `storeFile=${jks.replaceAll('\\', '/')}\nstorePassword=${pass}\nkeyAlias=${s[`ANDROID_KEY_ALIAS_${K}`] ?? 'upload'}\nkeyPassword=${pass}\n`,
        { mode: 0o600 },
      );
    }
    if (s[`GOOGLE_SERVICES_JSON_B64_${K}`]) {
      fs.writeFileSync(path.join(androidDir, 'app', 'google-services.json'), Buffer.from(s[`GOOGLE_SERVICES_JSON_B64_${K}`], 'base64'));
    }
    console.log(app, ': clé de signature et Firebase écrites');
  }
} else {
  console.error('commande inconnue :', cmd);
  process.exit(2);
}
