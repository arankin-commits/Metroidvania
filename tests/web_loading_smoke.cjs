// Run with: node tests/web_loading_smoke.cjs
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const html = fs.readFileSync(path.join(__dirname, '../web/loading.html'), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1]
	.replace('$GODOT_CONFIG', '{}').replace('$GODOT_THREADS_ENABLED', 'false');

function page({ missing = [], reject = false } = {}) {
	const elements = new Map();
	for (const id of ['status', 'status-progress', 'loading-percent', 'failure-message', 'status-notice', 'canvas']) {
		elements.set(id, { dataset: { phase: 'sound' }, textContent: '', hidden: true, removed: false,
			removeAttribute(name) { delete this[name]; }, remove() { this.removed = true; } });
	}
	const events = new Map();
	const timers = [];
	const frames = [];
	let callbacks;
	let resolveEngine;
	let rejectEngine;
	class Engine {
		static getMissingFeatures() { return missing; }
		startGame(options) {
			callbacks = options;
			return new Promise((resolve, reject) => { resolveEngine = resolve; rejectEngine = reject; });
		}
	}
	const window = { addEventListener(name, callback) { events.set(name, callback); } };
	vm.runInNewContext(script, {
		window, Engine, document: { getElementById: id => elements.get(id) },
		console: { error() {} },
		setTimeout(callback, delay) { timers.push({ callback, delay }); },
		requestAnimationFrame(callback) { frames.push(callback); },
	});
	events.get('DOMContentLoaded')();
	if (reject) rejectEngine(new Error('Network interrupted'));
	return {
		window, get: id => elements.get(id), timers, frames,
		progress: (current, total) => callbacks.onProgress(current, total),
		engineReady: () => resolveEngine(),
		menuReady: () => events.get('metroidvania-menu-ready')(),
		introFinished: () => timers[0].callback(),
		paint: () => { while (frames.length) frames.shift()(); },
	};
}

async function flush() { for (let i = 0; i < 8; i++) await Promise.resolve(); }

(async () => {
	const slow = page();
	assert.equal(slow.window.metroidvaniaWebLoader, true);
	assert.equal(slow.get('status').dataset.phase, 'sound');
	assert.equal(slow.timers[0].delay, 2000);
	slow.progress(25, 100);
	assert.equal(slow.get('loading-percent').textContent, '25%');
	slow.introFinished();
	assert.equal(slow.get('status').dataset.phase, 'loading');
	slow.engineReady();
	await flush();
	assert.equal(slow.get('status').removed, false, 'Wait for the actual game menu');
	slow.menuReady();
	await flush();
	assert.equal(slow.get('status').removed, false, 'Wait for the menu to paint');
	slow.paint();
	assert.equal(slow.get('status').removed, true);

	const cached = page();
	cached.engineReady(); cached.menuReady();
	await flush(); cached.paint();
	assert.equal(cached.get('status').removed, false, 'Cached startup must keep the full sound intro');
	cached.introFinished();
	await flush(); cached.paint();
	assert.equal(cached.get('status').removed, true);

	const unknown = page();
	unknown.progress(10, 100); unknown.progress(0, 0);
	assert.equal(unknown.get('loading-percent').textContent, '');
	assert.equal('value' in unknown.get('status-progress'), false, 'Unknown totals should be indeterminate');

	const failed = page({ reject: true });
	await flush();
	assert.equal(failed.get('status').dataset.phase, 'error');
	assert.match(failed.get('failure-message').textContent, /Network interrupted/);
	failed.introFinished();
	assert.equal(failed.get('status').dataset.phase, 'error', 'The intro timer must not conceal a failure');
	assert.equal(failed.get('status-notice').hidden, false);

	const unsupported = page({ missing: ['WebGL2'] });
	assert.equal(unsupported.get('status').dataset.phase, 'error');
	assert.match(unsupported.get('failure-message').textContent, /WebGL2/);
	assert.match(html, /data-phase="sound"/);
	console.log('WEB_LOADING_SMOKE_PASS');
})().catch(error => { console.error(error); process.exitCode = 1; });
