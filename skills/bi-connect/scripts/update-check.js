#!/usr/bin/env node
/**
 * update-check — cross-agent version-check helper for bi-superpowers.
 *
 * The SKILL.md preamble (see lib/generators/claude-plugin.js) invokes this
 * script at the start of every skill so the agent can surface an update
 * notice to the user when a newer version is on npm — without hitting the
 * network on every invocation. Cache TTL is 24h; repeated calls inside
 * that window are served from `~/.bi-superpowers/update-state.json`.
 *
 * Output (stdout, one line):
 *   UPTODATE                               when installed >= latest
 *   UPDATE_AVAILABLE <installed> <latest>  when installed < latest
 *   SNOOZED <iso>                          when user deferred the notice
 *
 * Flags:
 *   --force                 bypass cache (re-fetch npm, ignore snooze TTL)
 *   --silent-if-uptodate    suppress UPTODATE line (used by the preamble)
 *   --silent-if-snoozed     suppress SNOOZED line (used by the preamble)
 *   --json                  emit JSON instead of text
 *   --snooze 24h|48h|7d|clear   set (or clear) the snooze state and exit
 *   --reset                 delete the state file and exit (used post-upgrade)
 *   --state-dir <path>      override ~/.bi-superpowers/ (for tests)
 *   --package-name <name>   override the package name (for tests)
 *   -h, --help              show this help
 *
 * Exit code is always 0 when the script itself ran — errors during the
 * network fetch degrade to "no output" so the caller never blocks. A
 * non-zero exit means a user error (bad flags).
 *
 * Pure helpers (compareVersions, isCacheFresh, isSnoozed,
 * computeNextSnoozeUntil, readState, writeState, fetchLatestVersion) are
 * exported so unit tests can exercise them without spawning child
 * processes or hitting the network.
 */

'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');

const PACKAGE_NAME = 'bi-superpowers';
const CACHE_TTL_MS = 1000 * 60 * 60 * 24; // 24 hours
const HTTPS_TIMEOUT_MS = 5000;
// Rewritten at generation time when this helper is copied into
// `skills/<name>/scripts/update-check.js`. In the canonical source under
// `bin/commands/`, it stays null and we fall back to package.json.
const BUNDLED_INSTALLED_VERSION = "1.0.0";

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const out = {
    force: false,
    silentIfUptodate: false,
    silentIfSnoozed: false,
    json: false,
    snooze: null,
    reset: false,
    help: false,
    stateDir: null,
    packageName: null,
    installedVersion: null,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (a === '--force') out.force = true;
    else if (a === '--silent-if-uptodate') out.silentIfUptodate = true;
    else if (a === '--silent-if-snoozed') out.silentIfSnoozed = true;
    else if (a === '--json') out.json = true;
    else if (a === '--snooze') {
      out.snooze = argv[++i];
      if (out.snooze === undefined) {
        process.stderr.write(
          'update-check: --snooze requires a value (e.g. 24h, 48h, 7d, auto, clear)\n'
        );
        process.exit(1);
      }
    } else if (a === '--reset') out.reset = true;
    else if (a === '--state-dir') out.stateDir = argv[++i];
    else if (a === '--package-name') out.packageName = argv[++i];
    else if (a === '--installed-version') out.installedVersion = argv[++i];
    else if (a === '-h' || a === '--help') out.help = true;
    else {
      process.stderr.write(`update-check: unknown flag: ${a}\n`);
      process.exit(1);
    }
  }
  return out;
}

function help() {
  process.stdout.write(
    [
      'Usage: update-check [options]',
      '',
      'Prints one of: UPTODATE, UPDATE_AVAILABLE <installed> <latest>, SNOOZED <iso>.',
      '',
      'Options:',
      '  --force                 Bypass cache and snooze TTL',
      '  --silent-if-uptodate    Skip the UPTODATE line',
      '  --silent-if-snoozed     Skip the SNOOZED line',
      '  --json                  Emit JSON',
      '  --snooze <dur>          Set snooze state (24h|48h|7d) or "clear" to reset snooze',
      '  --reset                 Delete the state file (used after a successful upgrade)',
      '  --state-dir <path>      Override ~/.bi-superpowers/ (tests)',
      '  --package-name <name>   Override the package name (tests)',
      '  --installed-version <v> Override the installed version (generated skill bundles)',
      '  -h, --help              Show this help',
      '',
    ].join('\n')
  );
}

// ---------------------------------------------------------------------------
// Version comparison (semver-ish: MAJOR.MINOR.PATCH with optional -prerelease)
// No deps; handles the shapes bi-superpowers uses today.
// ---------------------------------------------------------------------------

/**
 * Compare two semver strings.
 * Returns -1 if a < b, 0 if equal, 1 if a > b.
 * Pre-release tags (`-alpha.1`) sort before the release per semver.
 */
function compareVersions(a, b) {
  const parse = (v) => {
    const [main, pre] = String(v).split('-');
    const parts = main.split('.').map((n) => parseInt(n, 10) || 0);
    while (parts.length < 3) parts.push(0);
    return { parts, pre: pre || null };
  };
  const va = parse(a);
  const vb = parse(b);
  for (let i = 0; i < 3; i += 1) {
    if (va.parts[i] !== vb.parts[i]) return va.parts[i] < vb.parts[i] ? -1 : 1;
  }
  // Main equal — pre-release < release.
  if (va.pre && !vb.pre) return -1;
  if (!va.pre && vb.pre) return 1;
  if (va.pre && vb.pre) {
    // Semver prerelease precedence: dot-separated identifiers compared
    // left-to-right; numeric identifiers compared numerically, numeric ranks
    // below alphanumeric, and a shorter identifier set has lower precedence.
    const pa = va.pre.split('.');
    const pb = vb.pre.split('.');
    for (let i = 0; i < Math.max(pa.length, pb.length); i += 1) {
      if (pa[i] === undefined) return -1;
      if (pb[i] === undefined) return 1;
      const an = /^\d+$/.test(pa[i]);
      const bn = /^\d+$/.test(pb[i]);
      if (an && bn) {
        const d = parseInt(pa[i], 10) - parseInt(pb[i], 10);
        if (d !== 0) return d < 0 ? -1 : 1;
      } else if (an !== bn) {
        return an ? -1 : 1;
      } else if (pa[i] !== pb[i]) {
        return pa[i] < pb[i] ? -1 : 1;
      }
    }
  }
  return 0;
}

// ---------------------------------------------------------------------------
// Cache + snooze state
// ---------------------------------------------------------------------------

function defaultStateDir() {
  return path.join(os.homedir(), '.bi-superpowers');
}

function stateFilePath(stateDir) {
  return path.join(stateDir, 'update-state.json');
}

function readState(stateDir) {
  const filePath = stateFilePath(stateDir);
  if (!fs.existsSync(filePath)) return null;
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (_) {
    // Malformed → treat as no cache.
    return null;
  }
}

function writeState(stateDir, state) {
  fs.mkdirSync(stateDir, { recursive: true });
  fs.writeFileSync(stateFilePath(stateDir), JSON.stringify(state, null, 2) + '\n');
}

function resetState(stateDir) {
  const filePath = stateFilePath(stateDir);
  if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
}

function isCacheFresh(state, now, ttlMs) {
  if (!state || !state.checkedAt) return false;
  const checkedAt = Date.parse(state.checkedAt);
  if (!Number.isFinite(checkedAt)) return false;
  return now - checkedAt < ttlMs;
}

function isSnoozed(state, now) {
  if (!state || !state.snoozeUntil) return false;
  const until = Date.parse(state.snoozeUntil);
  if (!Number.isFinite(until)) return false;
  return until > now;
}

// Snooze escalation: 24h → 48h → 7d (capped).
function computeNextSnoozeUntil(currentLevel, now) {
  const levels = [
    1000 * 60 * 60 * 24, // 24h
    1000 * 60 * 60 * 48, // 48h
    1000 * 60 * 60 * 24 * 7, // 7d
  ];
  const idx = Math.min(Math.max(currentLevel, 0), levels.length - 1);
  return new Date(now + levels[idx]).toISOString();
}

function parseSnoozeArg(arg, now, currentLevel) {
  if (arg === 'clear') return { clear: true };
  if (arg === '24h') return { until: new Date(now + 1000 * 60 * 60 * 24).toISOString(), level: 0 };
  if (arg === '48h') return { until: new Date(now + 1000 * 60 * 60 * 48).toISOString(), level: 1 };
  if (arg === '7d')
    return { until: new Date(now + 1000 * 60 * 60 * 24 * 7).toISOString(), level: 2 };
  if (arg === 'auto')
    return {
      until: computeNextSnoozeUntil(currentLevel, now),
      level: Math.min(currentLevel + 1, 2),
    };
  throw new Error(`invalid --snooze value: ${arg}. Expected 24h|48h|7d|auto|clear.`);
}

// ---------------------------------------------------------------------------
// npm registry fetch
// ---------------------------------------------------------------------------

/**
 * Fetch the latest published version of a package from the npm registry.
 * Never rejects with a network error — resolves null on timeout / failure
 * so callers always degrade gracefully.
 *
 * @param {string} packageName - e.g. "bi-superpowers"
 * @returns {Promise<string|null>}
 */
function fetchLatestVersion(packageName) {
  return new Promise((resolve) => {
    const encoded = packageName.replace('/', '%2F');
    const url = `https://registry.npmjs.org/${encoded}/latest`;

    const req = https.get(
      url,
      { headers: { Accept: 'application/vnd.npm.install-v1+json' } },
      (res) => {
        if (res.statusCode !== 200) {
          res.resume();
          resolve(null);
          return;
        }
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            const json = JSON.parse(body);
            resolve(typeof json.version === 'string' ? json.version : null);
          } catch (_) {
            resolve(null);
          }
        });
      }
    );
    req.on('error', () => resolve(null));
    req.setTimeout(HTTPS_TIMEOUT_MS, () => {
      req.destroy();
      resolve(null);
    });
  });
}

// ---------------------------------------------------------------------------
// Installed version — read from our own package.json
// ---------------------------------------------------------------------------

function readInstalledVersion(explicitVersion = null) {
  if (explicitVersion) {
    return String(explicitVersion);
  }
  if (BUNDLED_INSTALLED_VERSION) {
    return String(BUNDLED_INSTALLED_VERSION);
  }
  try {
    return require(path.join(__dirname, '..', '..', 'package.json')).version;
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Emit helpers
// ---------------------------------------------------------------------------

function emit(args, kind, payload) {
  if (args.json) {
    process.stdout.write(JSON.stringify({ status: kind, ...payload }) + '\n');
    return;
  }
  if (kind === 'UPTODATE' && args.silentIfUptodate) return;
  if (kind === 'SNOOZED' && args.silentIfSnoozed) return;

  if (kind === 'UPTODATE') process.stdout.write('UPTODATE\n');
  else if (kind === 'UPDATE_AVAILABLE')
    process.stdout.write(`UPDATE_AVAILABLE ${payload.installed} ${payload.latest}\n`);
  else if (kind === 'SNOOZED') process.stdout.write(`SNOOZED ${payload.until}\n`);
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    help();
    return;
  }

  const stateDir = args.stateDir || defaultStateDir();
  const packageName = args.packageName || PACKAGE_NAME;

  if (args.reset) {
    resetState(stateDir);
    return;
  }

  if (args.snooze) {
    const now = Date.now();
    const prior = readState(stateDir) || {};
    const parsed = parseSnoozeArg(args.snooze, now, prior.snoozeLevel || 0);
    if (parsed.clear) {
      writeState(stateDir, { ...prior, snoozeUntil: null, snoozeLevel: 0 });
    } else {
      writeState(stateDir, {
        ...prior,
        snoozeUntil: parsed.until,
        snoozeLevel: parsed.level,
      });
    }
    return;
  }

  const installed = readInstalledVersion(args.installedVersion);
  if (!installed) {
    // Installed version undetermined — nothing useful to report.
    return;
  }

  const now = Date.now();
  let state = readState(stateDir);

  // Snooze short-circuits everything except --force.
  if (!args.force && isSnoozed(state, now)) {
    emit(args, 'SNOOZED', { until: state.snoozeUntil });
    return;
  }

  // Use cached `latest` when the cache is fresh (unless --force).
  let latest = state && state.latest;
  if (args.force || !isCacheFresh(state, now, CACHE_TTL_MS)) {
    const fetched = await fetchLatestVersion(packageName);
    if (fetched) {
      latest = fetched;
      const nextState = {
        installed,
        latest,
        checkedAt: new Date(now).toISOString(),
        snoozeUntil: (state && state.snoozeUntil) || null,
        snoozeLevel: (state && state.snoozeLevel) || 0,
      };
      writeState(stateDir, nextState);
      state = nextState;
    }
    // If fetched is null (network fail), we keep using the previous cache
    // — or emit nothing if there's no cache at all.
  }

  if (!latest) {
    // No cached value and no fetch — nothing to say.
    return;
  }

  if (compareVersions(installed, latest) < 0) {
    emit(args, 'UPDATE_AVAILABLE', { installed, latest });
  } else {
    emit(args, 'UPTODATE', { installed, latest });
  }
}

module.exports = {
  parseArgs,
  compareVersions,
  isCacheFresh,
  isSnoozed,
  computeNextSnoozeUntil,
  parseSnoozeArg,
  readState,
  writeState,
  resetState,
  fetchLatestVersion,
  readInstalledVersion,
  CACHE_TTL_MS,
  PACKAGE_NAME,
};

if (require.main === module) {
  main().catch((err) => {
    // Never throw out of the CLI — the preamble must not break skill invocation.
    process.stderr.write(`update-check: ${err.message}\n`);
    process.exit(0);
  });
}
