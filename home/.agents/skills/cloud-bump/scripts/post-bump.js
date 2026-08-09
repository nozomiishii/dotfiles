// /cloud-bump 承認後ステップ: fresh GET の digest 照合が通った場合だけ init_script の bump 行を更新して POST し、検証 GET まで行う。
// 実行前に <network-log-derived-org-id> <network-log-derived-env-id> <approved-snapshot-sha256> <approved-bump-line> を実値へ置換する (このファイル自体は書き換えない)。
// 承認前 call の lexical binding は使わず、この 1 call で自己完結させる。
const assertClaudeContext = () => {
  if (location.origin !== 'https://claude.ai' || !location.pathname.startsWith('/code')) {
    throw new Error('unexpected tab origin or path');
  }
};
const canonicalize = value => Array.isArray(value)
  ? value.map(canonicalize)
  : value && typeof value === 'object'
    ? Object.fromEntries(Object.keys(value).sort().map(key => [key, canonicalize(value[key])]))
    : value;
const sha256 = async value => {
  const bytes = new TextEncoder().encode(JSON.stringify(canonicalize(value)));
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('');
};
const orgId = '<network-log-derived-org-id>';
const envId = '<network-log-derived-env-id>';
const approvedSnapshotDigest = '<approved-snapshot-sha256>';
const approvedBumpLine = '<approved-bump-line>';
if (!/^[A-Za-z0-9_-]{8,128}$/.test(orgId)) throw new Error('invalid orgId');
if (!/^[A-Za-z0-9_-]{8,128}$/.test(envId)) throw new Error('invalid envId');
if (!/^[a-f0-9]{64}$/.test(approvedSnapshotDigest)) throw new Error('invalid approved snapshot digest');
if (!/^# bump \d{4}-\d{2}-\d{2} \d{2}:\d{2}$/.test(approvedBumpLine)) throw new Error('invalid approved bump line');
const endpoint = `https://claude.ai/v1/environment_providers/private/organizations/${encodeURIComponent(orgId)}/environments/${encodeURIComponent(envId)}`;

assertClaudeContext();
const getResp = await fetch(endpoint);
if (!getResp.ok) throw new Error(`GET failed: ${getResp.status}`);
const env = await getResp.json();
if (await sha256(env) !== approvedSnapshotDigest) {
  throw new Error('environment changed after approval');
}
const originalInit = String(env.config.init_script ?? '');
const bumpPattern = /^# bump \d{4}-\d{2}-\d{2} \d{2}:\d{2}(?=\n|$)/;
const stripBump = value => value.replace(/^# bump \d{4}-\d{2}-\d{2} \d{2}:\d{2}(?:\n|$)/, '');
const updatedInit = bumpPattern.test(originalInit)
  ? originalInit.replace(bumpPattern, approvedBumpLine)
  : `${approvedBumpLine}\n${originalInit}`;

if (stripBump(updatedInit) !== stripBump(originalInit)) {
  throw new Error('init_script body changed outside the bump line');
}

const updated = {
  name: env.name,
  description: env.description ?? '',
  config: { ...env.config, init_script: updatedInit }
};
assertClaudeContext();
const resp = await fetch(endpoint, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(updated)
});
if (!resp.ok) throw new Error(`POST failed: ${resp.status}`);

assertClaudeContext();
const verifyResp = await fetch(endpoint);
if (!verifyResp.ok) throw new Error(`verification GET failed: ${verifyResp.status}`);
const after = await verifyResp.json();
const beforeRest = { ...env.config }; delete beforeRest.init_script;
const afterRest = { ...after.config }; delete afterRest.init_script;
if (after.config.init_script !== updatedInit ||
    after.name !== env.name || (after.description ?? '') !== (env.description ?? '') ||
    JSON.stringify(afterRest) !== JSON.stringify(beforeRest)) {
  throw new Error('POST verification mismatch');
}
