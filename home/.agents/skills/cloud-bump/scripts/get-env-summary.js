// /cloud-bump 承認前ステップ: 現在の環境設定を GET し、差分承認に使う safe summary を返す。
// 実行前に <network-log-derived-org-id> と <network-log-derived-env-id> を実値へ置換する (このファイル自体は書き換えない)。
// claude.ai/code を開いた固定 tab で javascript_tool (Codex は Playwright 評価) として実行する。
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
if (!/^[A-Za-z0-9_-]{8,128}$/.test(orgId)) throw new Error('invalid orgId');
if (!/^[A-Za-z0-9_-]{8,128}$/.test(envId)) throw new Error('invalid envId');
const endpoint = `https://claude.ai/v1/environment_providers/private/organizations/${encodeURIComponent(orgId)}/environments/${encodeURIComponent(envId)}`;
assertClaudeContext();
const getResp = await fetch(endpoint);
if (!getResp.ok) throw new Error(`GET failed: ${getResp.status}`);
const env = await getResp.json();
const originalInit = String(env.config.init_script ?? '');
const now = new Date();
const pad = value => String(value).padStart(2, '0');
const proposedBumpLine = `# bump ${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`;
const snapshotDigest = await sha256(env);
({
  snapshotDigest,
  environmentId: env.environment_id ?? envId,
  name: env.name,
  currentBumpLine: originalInit.match(/^# bump \d{4}-\d{2}-\d{2} \d{2}:\d{2}(?=\n|$)/)?.[0] ?? null,
  proposedBumpLine
});
