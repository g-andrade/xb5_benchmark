#!/usr/bin/env python3
"""Generate an interactive HTML benchmark report from a merged_data.json file.

Usage:
    python3 generate_report.py output/my_run
    # writes output/my_run/report.html
"""

import json
import re
import sys
from pathlib import Path


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <run_dir>", file=sys.stderr)
        sys.exit(1)
    run_dir = Path(sys.argv[1])
    merged = run_dir / "merged_data.json"
    if not merged.exists():
        print(f"Error: {merged} not found.", file=sys.stderr)
        print("Run Xb5Benchmark.merge_into_single_json/1 first.", file=sys.stderr)
        sys.exit(1)
    with open(merged) as f:
        data = json.load(f)
    out = run_dir / "report.html"
    out.write_text(render(data))
    orig = merged.stat().st_size
    new  = out.stat().st_size
    print(f"Report written to: {out}  ({new // 1024} KB, down from {orig // 1024} KB JSON)")


def shorten_cpu(cpu):
    """Trim trademark markers and redundant words from CPU strings.

    'Intel(R) Core(TM) i5-3550 CPU @ 3.30GHz' -> 'Intel Core i5-3550 @ 3.30GHz'
    """
    cpu = re.sub(r'\(R\)|\(TM\)', '', cpu)
    cpu = re.sub(r'\bCPU\b', '', cpu)
    cpu = re.sub(r'  +', ' ', cpu).strip()
    return cpu


def render(data):
    stripped = strip_data(data)
    escaped  = json.dumps(stripped, separators=(",", ":")).replace("</", "<\\/")
    cpu   = shorten_cpu(data.get("system_info", {}).get("cpu_speed", "Unknown CPU"))
    title = json.dumps(f"xb5 - {cpu}")
    return TEMPLATE.replace("/*__DATA__*/", escaped).replace("/*__TITLE__*/", title)


def strip_data(data):
    """Keep only the fields the report actually uses, shrinking the payload."""
    return {
        "system_info": data["system_info"],
        "runtime_data": _strip_metric(data.get("runtime_data", {})),
        "memory_data":  _strip_metric(data.get("memory_data", {})),
    }


def _strip_metric(metric):
    out = {}
    for bt, groups in metric.items():
        out[bt] = {}
        for gid, entries in groups.items():
            out[bt][gid] = [
                {
                    "impl_mod":         e["impl_mod"],
                    "impl_description": e["impl_description"],
                    "tweaks":           e.get("tweaks", "none"),
                    "measurements": [
                        {
                            "n":      m["n"],
                            "median": m["median"],
                            "p25":    m["percentiles"]["25"],
                            "p75":    m["percentiles"]["75"],
                        }
                        for m in e["measurements"]
                    ],
                }
                for e in entries
            ]
    return out


# ---------------------------------------------------------------------------
# HTML / CSS / JS template
# ---------------------------------------------------------------------------

TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>xb5 Benchmark Report</title>
<script src="https://cdn.plot.ly/plotly-2.27.0.min.js" charset="utf-8"></script>
<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
  font-size: 14px; color: #222; background: #f0f2f5;
  display: flex; flex-direction: column; height: 100vh; overflow: hidden;
}
/* ---- Header ---- */
#header {
  background: #1c2233; color: #e8eaf6;
  padding: 10px 20px 8px; flex-shrink: 0;
}
.hdr-top { display: flex; align-items: baseline; gap: 16px; margin-bottom: 8px; }
#hdr-title { font-size: 15px; font-weight: 700; color: #fff; white-space: nowrap; }
#sysinfo   { font-size: 11px; color: #9fa8da; }
.hdr-ctrls { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.hdr-ctrls .cg { display: flex; align-items: center; gap: 5px; }
.hdr-ctrls label { font-size: 11px; color: #c5cae9; white-space: nowrap; }
.hdr-ctrls select {
  font-size: 12px; padding: 3px 6px; border-radius: 4px;
  background: #2a3250; color: #e8eaf6; border: 1px solid #3a4470;
  max-width: 260px;
}
/* ---- Main ---- */
#main { flex: 1; overflow-y: auto; padding: 20px 24px; background: #f0f2f5; }
/* ---- Overview ---- */
.ov-header { font-size: 12px; color: #888; margin-bottom: 10px; }
.ov-th-n { display: block; font-size: 10px; font-weight: normal; color: #aaa; margin-top: 2px; }
.ov-table {
  border-collapse: collapse; background: #fff; width: 100%; max-width: 680px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08); border-radius: 6px; overflow: hidden;
}
.ov-table th {
  background: #f8f9fb; padding: 7px 10px; text-align: left;
  font-size: 11px; font-weight: 700; color: #777; border-bottom: 2px solid #e8eaf0;
}
.ov-table th.ov-th-ratio { text-align: center; }
.ov-table td { padding: 6px 10px; border-bottom: 1px solid #f0f2f5; font-size: 13px; }
.ov-table td.ov-td-ratio { text-align: center; }
.ov-table tr:last-child td { border-bottom: none; }
.ov-table tr:hover td { background: #fafbff; }
.ov-table td.op-name { color: #1a73e8; cursor: pointer; font-weight: 500; }
.ov-table td.op-name:hover { text-decoration: underline; }
.ov-divider td {
  background: #f4f6fb; font-size: 10px; font-weight: 700; color: #999;
  text-transform: uppercase; letter-spacing: 0.06em; padding: 5px 14px 4px;
  border-bottom: 1px solid #e8eaf0;
}
/* ---- Ratio chips ---- */
.r-chip {
  display: inline-block; padding: 2px 8px; border-radius: 10px;
  font-size: 11px; font-weight: 700; min-width: 44px; text-align: center;
}
.r-great { background: #c8e6c9; color: #1b5e20; }
.r-good  { background: #dcedc8; color: #33691e; }
.r-even  { background: #fff9c4; color: #7a6e00; }
.r-bad   { background: #ffe0b2; color: #bf360c; }
.r-worse { background: #ffcdd2; color: #b71c1c; }
.r-na    { color: #bbb; font-size: 12px; }
/* ---- Family detail ---- */
.detail-card {
  background: #fff; border-radius: 8px; padding: 22px 24px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.09); max-width: 900px;
}
.detail-card.memory-mode { background: #f8f4ff; }
.back-btn {
  display: inline-block; font-size: 12px; color: #1a73e8;
  cursor: pointer; margin-bottom: 14px;
}
.back-btn:hover { text-decoration: underline; }
.detail-card h2 { font-size: 17px; font-weight: 700; margin-bottom: 2px; }
.detail-gid  { font-size: 11px; color: #aaa; font-family: monospace; margin-bottom: 2px; }
.detail-subtitle { font-size: 12px; color: #888; margin-bottom: 14px; }
.ctrl-row { display: flex; gap: 14px; margin-bottom: 16px; flex-wrap: wrap; align-items: center; }
.ctrl-grp2 { display: flex; align-items: center; gap: 6px; }
.ctrl-grp2 label { font-size: 11px; font-weight: 700; color: #888; }
.btn-grp { display: flex; }
.btn-grp button {
  padding: 4px 10px; font-size: 11px; border: 1px solid #ccc;
  background: #fff; cursor: pointer; color: #444;
}
.btn-grp button:first-child { border-radius: 4px 0 0 4px; }
.btn-grp button:last-child  { border-radius: 0 4px 4px 0; }
.btn-grp button + button    { border-left: none; }
.btn-grp button.active { background: #1c2233; color: #fff; border-color: #1c2233; }
.btn-grp button:hover:not(.active) { background: #f0f2f5; }
.chart-lbl {
  font-size: 11px; font-weight: 700; color: #999;
  letter-spacing: 0.05em; text-transform: uppercase; margin-bottom: 4px; margin-top: 14px;
}
.chart-box { width: 100%; height: 400px; }
.pct-box   { width: 100%; height: 220px; }
.no-data { color: #aaa; font-style: italic; padding: 16px 0; }
</style>
</head>
<body>

<script>const DATA = /*__DATA__*/; const PAGE_TITLE = /*__TITLE__*/;</script>

<div id="header">
  <div class="hdr-top">
    <h1 id="hdr-title">xb5 Benchmark</h1>
    <div id="sysinfo"></div>
  </div>
  <div class="hdr-ctrls">
    <div class="cg"><label>Section</label><select id="sel-section"></select></div>
    <div class="cg"><label>Operation</label><select id="sel-op"></select></div>
    <div class="cg"><label>Build type</label><select id="sel-build"></select></div>
    <div class="cg">
      <label>Metric</label>
      <select id="sel-metric">
        <option value="runtime">Runtime</option>
        <option value="memory">Memory</option>
      </select>
    </div>
  </div>
</div>

<main id="main"></main>

<script>
// ============================================================
// Configuration
// ============================================================

var IMPL_COLORS = {
  'gb_sets':   '#4373c2',
  'xb5_sets':  '#e8702a',
  'gb_trees':  '#22963f',
  'xb5_trees': '#c93535',
  'xb5_bag':   '#7b5ea7'
};

var BUILD_LABELS = {
  'from_ordset_or_orddict': 'From Ordset/Orddict',
  'sequential':             'Sequential',
  'random':                 'Random',
  'xb5_adversarial':        'xb5 Adversarial'
};

// families may have:
//   type: 'simple' | 'param2' | 'named'
//   exclusive: true  => no baseline comparison (xb5_bag-only ops)
//   div: string      => subgroup divider row (not a navigable family)
var SECTIONS = [
  {
    id: 'sets', label: 'Sets: xb5_sets vs gb_sets',
    primary: 'xb5_sets', baseline: 'gb_sets',
    families: [
      { div: 'Binary set operations' },
      { id: 'union',        label: 'union',        type: 'param2' },
      { id: 'intersection', label: 'intersection', type: 'param2' },
      { id: 'difference',   label: 'difference',   type: 'param2' },
      { id: 'is_disjoint',  label: 'is_disjoint',  type: 'param2' },
      { id: 'is_equal',     label: 'is_equal',     type: 'named'  },
      { id: 'is_subset',    label: 'is_subset',    type: 'named'  },
      { div: 'Element operations' },
      { id: 'add_new_x300',            label: 'add \u00d7300 [new key]',       type: 'simple' },
      { id: 'add_existing_x300',       label: 'add \u00d7300 [existing key]',  type: 'simple' },
      { id: 'insert_x300',             label: 'insert \u00d7300 [new key]',    type: 'simple' },
      { id: 'delete_x300',             label: 'delete \u00d7300 [existing]',   type: 'simple' },
      { id: 'delete_any_missing_x100', label: 'delete_any \u00d7100 [miss]',   type: 'simple' },
      { id: 'is_member_existing_x100', label: 'is_member \u00d7100 [hit]',     type: 'simple' },
      { id: 'is_member_missing_x100',  label: 'is_member \u00d7100 [miss]',    type: 'simple' },
      { div: 'Build' },
      { id: 'from_list',                  label: 'from_list',    type: 'simple' },
      { id: 'from_ordset / from_orddict', label: 'from_ordset',  type: 'simple' },
      { div: 'Traversal & functional' },
      { id: 'iterate',              label: 'iterate',                  type: 'simple' },
      { id: 'to_list',              label: 'to_list',                  type: 'simple' },
      { id: 'foldl',                label: 'foldl',                    type: 'simple' },
      { id: 'map',                  label: 'map',                      type: 'simple' },
      { id: 'filter_all',           label: 'filter [all pass]',        type: 'simple' },
      { id: 'filter_none',          label: 'filter [none pass]',       type: 'simple' },
      { id: 'filtermap_all',        label: 'filtermap [all keep]',     type: 'simple' },
      { id: 'filtermap_all_mapped', label: 'filtermap [all map]',      type: 'simple' },
      { id: 'filtermap_none',       label: 'filtermap [none keep]',    type: 'simple' },
      { div: 'Min, max & neighbors' },
      { id: 'largest',            label: 'largest',               type: 'simple' },
      { id: 'smaller_x100',       label: 'smaller \u00d7100',     type: 'simple' },
      { id: 'smallest',           label: 'smallest',              type: 'simple' },
      { id: 'larger_x100',        label: 'larger \u00d7100',      type: 'simple' },
      { id: 'take_largest_x300',  label: 'take_largest \u00d7300', type: 'simple' },
      { id: 'take_smallest_x300', label: 'take_smallest \u00d7300', type: 'simple' },
      { id: 'take_smallest + insert largest x300', label: 'take_smallest + insert_largest \u00d7300', type: 'simple' }
    ]
  },
  {
    id: 'trees', label: 'Trees: xb5_trees vs gb_trees',
    primary: 'xb5_trees', baseline: 'gb_trees',
    families: [
      { div: 'Lookup & mutation' },
      { id: 'get_x100',              label: 'get \u00d7100',                type: 'simple' },
      { id: 'lookup_existing_x100',  label: 'lookup \u00d7100 [hit]',       type: 'simple' },
      { id: 'lookup_missing_x100',   label: 'lookup \u00d7100 [miss]',      type: 'simple' },
      { id: 'update_x300',           label: 'update \u00d7300',             type: 'simple' },
      { id: 'take_x300',             label: 'take \u00d7300 [existing]',    type: 'simple' },
      { id: 'take_any_missing_x100', label: 'take_any \u00d7100 [miss]',    type: 'simple' },
      { div: 'Element operations' },
      { id: 'add_new_x300',            label: 'enter \u00d7300 [new key]',     type: 'simple' },
      { id: 'add_existing_x300',       label: 'enter \u00d7300 [existing key]', type: 'simple' },
      { id: 'insert_x300',             label: 'insert \u00d7300 [new key]',    type: 'simple' },
      { id: 'delete_x300',             label: 'delete \u00d7300 [existing]',   type: 'simple' },
      { id: 'delete_any_missing_x100', label: 'delete_any \u00d7100 [miss]',   type: 'simple' },
      { id: 'is_member_existing_x100', label: 'is_defined \u00d7100 [hit]',    type: 'simple' },
      { id: 'is_member_missing_x100',  label: 'is_defined \u00d7100 [miss]',   type: 'simple' },
      { div: 'Build' },
      { id: 'from_ordset / from_orddict', label: 'from_orddict',  type: 'simple' },
      { div: 'Traversal' },
      { id: 'iterate',  label: 'iterate',  type: 'simple' },
      { id: 'keys',     label: 'keys',     type: 'simple' },
      { id: 'values',   label: 'values',   type: 'simple' },
      { id: 'to_list',  label: 'to_list',  type: 'simple' },
      { id: 'map',      label: 'map',      type: 'simple' },
      { div: 'Min, max & neighbors' },
      { id: 'largest',            label: 'largest',               type: 'simple' },
      { id: 'smaller_x100',       label: 'smaller \u00d7100',     type: 'simple' },
      { id: 'smallest',           label: 'smallest',              type: 'simple' },
      { id: 'larger_x100',        label: 'larger \u00d7100',      type: 'simple' },
      { id: 'take_largest_x300',  label: 'take_largest \u00d7300', type: 'simple' },
      { id: 'take_smallest_x300', label: 'take_smallest \u00d7300', type: 'simple' },
      { id: 'take_smallest + insert largest x300', label: 'take_smallest + insert_largest \u00d7300', type: 'simple' }
    ]
  },
  {
    id: 'bag', label: 'Bag: xb5_bag vs gb_sets',
    primary: 'xb5_bag', baseline: 'gb_sets',
    families: [
      { div: 'Order-statistic operations (bag-exclusive)' },
      { id: 'nth_x100',           label: 'nth \u00d7100',              type: 'simple', exclusive: true },
      { id: 'rank_existing_x100', label: 'rank \u00d7100 [existing]',  type: 'simple', exclusive: true },
      { div: 'Element operations' },
      { id: 'add_new_x300',            label: 'add \u00d7300 [new key]',      type: 'simple' },
      // noOverview: xb5_bag allows duplicate keys so adding an existing key is a real insertion,
      // whereas gb_sets silently ignores it — different semantics, not a fair comparison.
      { id: 'add_existing_x300',       label: 'add \u00d7300 [existing key]', type: 'simple', noOverview: true },
      { id: 'insert_x300',             label: 'insert \u00d7300 [new key]',   type: 'simple' },
      { id: 'delete_x300',             label: 'delete \u00d7300 [existing]',  type: 'simple' },
      { id: 'delete_any_missing_x100', label: 'delete_any \u00d7100 [miss]',  type: 'simple' },
      { id: 'is_member_existing_x100', label: 'is_member \u00d7100 [hit]',    type: 'simple' },
      { id: 'is_member_missing_x100',  label: 'is_member \u00d7100 [miss]',   type: 'simple' },
      { div: 'Build' },
      { id: 'from_list',                  label: 'from_list',    type: 'simple' },
      { id: 'from_ordset / from_orddict', label: 'from_ordset',  type: 'simple' },
      { div: 'Traversal & functional' },
      { id: 'iterate',              label: 'iterate',               type: 'simple' },
      { id: 'to_list',              label: 'to_list',               type: 'simple' },
      { id: 'foldl',                label: 'foldl',                 type: 'simple' },
      { id: 'map',                  label: 'map',                   type: 'simple' },
      { id: 'filter_all',           label: 'filter [all pass]',     type: 'simple' },
      { id: 'filter_none',          label: 'filter [none pass]',    type: 'simple' },
      { id: 'filtermap_all',        label: 'filtermap [all keep]',  type: 'simple' },
      { id: 'filtermap_all_mapped', label: 'filtermap [all map]',   type: 'simple' },
      { id: 'filtermap_none',       label: 'filtermap [none keep]', type: 'simple' },
      { div: 'Min, max & neighbors' },
      { id: 'largest',            label: 'largest',               type: 'simple' },
      { id: 'smaller_x100',       label: 'smaller \u00d7100',     type: 'simple' },
      { id: 'smallest',           label: 'smallest',              type: 'simple' },
      { id: 'larger_x100',        label: 'larger \u00d7100',      type: 'simple' },
      { id: 'take_largest_x300',  label: 'take_largest \u00d7300', type: 'simple' },
      { id: 'take_smallest_x300', label: 'take_smallest \u00d7300', type: 'simple' },
      { id: 'take_smallest + insert largest x300', label: 'take_smallest + insert_largest \u00d7300', type: 'simple' }
    ]
  }
];

// ============================================================
// State
// ============================================================

var state = {
  si:        0,
  fi:        -1,              // -1 = overview
  buildType: 'from_ordset_or_orddict',
  metric:    'runtime'
};

var fsel = {};  // 'si:fi' -> { overlap, size, variant }

function getFsel(si, fi) {
  var k = si + ':' + fi;
  if (!fsel[k]) fsel[k] = {};
  return fsel[k];
}

// ============================================================
// Browser history & URL hash routing
// ============================================================

function stateToHash(s) {
  var sec = SECTIONS[s.si];
  var famPart = s.fi === -1 ? 'overview' : encodeURIComponent(sec.families[s.fi].id);
  return '#' + sec.id + '/' + famPart + '/' + s.buildType + '/' + s.metric;
}

function hashToState(hash) {
  if (!hash || hash.length < 2) return null;
  var parts = hash.slice(1).split('/');
  if (parts.length < 4) return null;
  var si = SECTIONS.findIndex(function(s) { return s.id === parts[0]; });
  if (si === -1) return null;
  var famId = decodeURIComponent(parts[1]);
  var fi;
  if (famId === 'overview') {
    fi = -1;
  } else {
    var fIdx = SECTIONS[si].families.findIndex(function(f) { return !f.div && !f.noOverview && f.id === famId; });
    if (fIdx === -1) return null;
    fi = fIdx;
  }
  var buildType = parts[2];
  var metric    = parts[3];
  if (!BUILD_LABELS[buildType] || (metric !== 'runtime' && metric !== 'memory')) return null;
  return { si: si, fi: fi, buildType: buildType, metric: metric };
}

function stateTitle(s) {
  var sec  = SECTIONS[s.si];
  var base = PAGE_TITLE + ' - ' + sec.label;
  return s.fi === -1 ? base + ' - Overview' : base + ' - ' + sec.families[s.fi].label;
}

function pushHistory() {
  var hash  = stateToHash(state);
  var title = stateTitle(state);
  document.title = title;
  history.pushState({ si: state.si, fi: state.fi, buildType: state.buildType, metric: state.metric }, title, hash);
}

window.addEventListener('popstate', function(e) {
  if (!e.state) return;
  state.si        = e.state.si;
  state.fi        = e.state.fi;
  state.buildType = e.state.buildType;
  state.metric    = e.state.metric;
  document.title  = stateTitle(state);
  document.getElementById('sel-section').value = state.si;
  document.getElementById('sel-build').value   = state.buildType;
  document.getElementById('sel-metric').value  = state.metric;
  populateOpSelect();   // rebuilds options for state.si, sets value to state.fi
  rerender();
});

// ============================================================
// Data helpers
// ============================================================

function getMetricSrc() {
  return state.metric === 'runtime' ? DATA.runtime_data : DATA.memory_data;
}

function getEntries(buildType, groupId) {
  var src = getMetricSrc();
  return ((src[buildType] || {})[groupId]) || [];
}

function getValAt(measurements, n, field) {
  var m = measurements.find(function(x) { return x.n === n; });
  return m ? (m[field] !== undefined ? m[field] : null) : null;
}

function getAllN() {
  var ns = new Set();
  var src = getMetricSrc();
  var bts = Object.keys(src);
  if (!bts.length) return [];
  var gids = Object.keys(src[bts[0]]);
  if (!gids.length) return [];
  var entries = src[bts[0]][gids[0]];
  if (entries && entries[0]) {
    entries[0].measurements.forEach(function(m) { ns.add(m.n); });
  }
  return Array.from(ns).sort(function(a, b) { return a - b; });
}

function parseParam2(groupId) {
  var m = groupId.match(/^(.+)_([0-9]{3})_([0-9]{4})$/);
  return m ? { family: m[1], overlap: m[2], size: m[3] } : null;
}

function getParam2Variants(familyId, buildType) {
  var src = getMetricSrc();
  var groups = src[buildType] || {};
  var overlaps = new Set(), sizes = new Set();
  Object.keys(groups).forEach(function(key) {
    var p = parseParam2(key);
    if (p && p.family === familyId) { overlaps.add(p.overlap); sizes.add(p.size); }
  });
  return { overlaps: Array.from(overlaps).sort(), sizes: Array.from(sizes).sort() };
}

function getNamedVariants(familyId, buildType) {
  var src = getMetricSrc();
  return Object.keys(src[buildType] || {})
    .filter(function(k) { return k.startsWith(familyId + ' ['); })
    .sort();
}

function getGroupId(si, fi) {
  var fam = SECTIONS[si].families[fi];
  var s   = getFsel(si, fi);

  if (fam.type === 'param2') {
    var v = getParam2Variants(fam.id, state.buildType);
    if (!s.overlap) s.overlap = v.overlaps.find(function(o) { return o === '050'; }) || v.overlaps[0];
    if (!s.size)    s.size    = v.sizes.find(function(x) { return x === '0500'; }) || v.sizes[0];
    return (s.overlap && s.size) ? fam.id + '_' + s.overlap + '_' + s.size : null;
  }
  if (fam.type === 'named') {
    var variants = getNamedVariants(fam.id, state.buildType);
    if (!s.variant) s.variant = variants.find(function(v) { return v.indexOf('50%') >= 0; }) || variants[0];
    return s.variant || null;
  }
  return fam.id;
}

function repGroupId(fam, buildType) {
  if (fam.type === 'param2') {
    var src = getMetricSrc();
    var g = src[buildType] || {};
    var cand = fam.id + '_050_0500';
    if (g[cand]) return cand;
    return Object.keys(g).find(function(k) { var p = parseParam2(k); return p && p.family === fam.id; }) || null;
  }
  if (fam.type === 'named') {
    var src2 = getMetricSrc();
    var keys = Object.keys(src2[buildType] || {}).filter(function(k) { return k.startsWith(fam.id + ' ['); });
    return keys.find(function(v) { return v.indexOf('50%') >= 0; }) || keys[0] || null;
  }
  return fam.id;
}

function computeRatio(fam, buildType, primary, baseline, n) {
  var gid = repGroupId(fam, buildType);
  if (!gid) return null;
  var entries = getEntries(buildType, gid);
  var ep = entries.find(function(e) { return e.impl_mod === primary; });
  var eb = entries.find(function(e) { return e.impl_mod === baseline; });
  if (!ep || !eb) return null;
  var vp = getValAt(ep.measurements, n, 'median');
  var vb = getValAt(eb.measurements, n, 'median');
  return (vp && vb) ? vp / vb : null;
}

// Proportional display: "130%" means xb5 is 130% as fast as baseline (i.e. 30% faster).
// "78%" means xb5 is only 78% as fast (22% slower).
function ratioHtml(ratio) {
  if (ratio === null) return '<span class="r-na">-</span>';
  var pct = Math.round(ratio * 100);
  var cls;
  if (state.metric === 'runtime') {
    // Higher = xb5 faster
    if      (ratio > 1.15) cls = 'r-great';
    else if (ratio > 1.05) cls = 'r-good';
    else if (ratio > 0.95) cls = 'r-even';
    else if (ratio > 0.70) cls = 'r-bad';
    else                   cls = 'r-worse';
  } else {
    // Lower = xb5 uses less memory
    if      (ratio < 0.85) cls = 'r-great';
    else if (ratio < 0.95) cls = 'r-good';
    else if (ratio < 1.05) cls = 'r-even';
    else if (ratio < 1.30) cls = 'r-bad';
    else                   cls = 'r-worse';
  }
  return '<span class="r-chip ' + cls + '">' + pct + '%</span>';
}

// ============================================================
// Chart helpers
// ============================================================

var activePlots = [];

function purgeCharts() {
  activePlots.forEach(function(id) { var el = document.getElementById(id); if (el) Plotly.purge(el); });
  activePlots = [];
}

function hexToRgb(hex) {
  return parseInt(hex.slice(1,3),16) + ',' + parseInt(hex.slice(3,5),16) + ',' + parseInt(hex.slice(5,7),16);
}

function buildMainChart(containerId, groupId, sec) {
  var el = document.getElementById(containerId);
  var allEntries = getEntries(state.buildType, groupId);
  var entries = allEntries.filter(function(e) {
    return e.impl_mod === sec.primary || e.impl_mod === sec.baseline;
  });
  if (!entries.length) {
    el.innerHTML = '<div class="no-data">No data for this build type / section.</div>';
    return;
  }

  var allN    = getAllN();
  var plotN   = allN.filter(function(n) { return n > 0; });
  var traces  = [];
  var isRuntime = state.metric === 'runtime';

  entries.forEach(function(entry) {
    var color   = IMPL_COLORS[entry.impl_mod] || '#888';
    var rgb     = hexToRgb(color);
    var medians = plotN.map(function(n) { return getValAt(entry.measurements, n, 'median'); });
    var p25s    = plotN.map(function(n) { return getValAt(entry.measurements, n, 'p25'); });
    var p75s    = plotN.map(function(n) { return getValAt(entry.measurements, n, 'p75'); });
    var label   = entry.impl_description || entry.impl_mod;
    var dash    = isRuntime ? 'solid' : 'dash';

    traces.push({
      x: plotN.concat(plotN.slice().reverse()),
      y: p75s.concat(p25s.slice().reverse()),
      type: 'scatter', mode: 'lines', fill: 'toself',
      fillcolor: 'rgba(' + rgb + ',0.13)', line: { width: 0 },
      showlegend: false, hoverinfo: 'skip', name: entry.impl_mod + '__band'
    });
    traces.push({
      x: plotN, y: medians, type: 'scatter', mode: 'lines+markers',
      name: label,
      line: { color: color, width: 2, dash: dash },
      marker: { size: 4, color: color, symbol: isRuntime ? 'circle' : 'circle-open' },
      hovertemplate: label + '<br>n=%{x}<br>%{y:.1f}<extra></extra>'
    });
  });

  var yTitle = isRuntime ? 'Iterations / sec' : 'Memory (bytes)';
  var bgColor = isRuntime ? 'white' : '#fdfbff';

  Plotly.newPlot(el, traces, {
    margin: { t: 8, r: 16, b: 48, l: 72 },
    xaxis: { title: 'Collection size (n)', gridcolor: '#ebebeb' },
    yaxis: { title: yTitle, gridcolor: '#ebebeb', rangemode: 'tozero' },
    legend: { bgcolor: 'rgba(255,255,255,0.85)', bordercolor: '#ddd', borderwidth: 1 },
    paper_bgcolor: bgColor, plot_bgcolor: bgColor, hovermode: 'x unified'
  }, { responsive: true, displayModeBar: false });

  activePlots.push(containerId);
}

function buildPctChart(containerId, groupId, sec) {
  var el = document.getElementById(containerId);
  var entries = getEntries(state.buildType, groupId);
  var ep = entries.find(function(e) { return e.impl_mod === sec.primary; });
  var eb = entries.find(function(e) { return e.impl_mod === sec.baseline; });
  if (!ep || !eb) {
    el.innerHTML = '<div class="no-data">Comparison data not available.</div>';
    return;
  }

  var allN  = getAllN();
  var plotN = allN.filter(function(n) { return n > 0; });
  var isRuntime = state.metric === 'runtime';

  // Proportional: 100% = same as baseline, >100% = xb5 ahead (for runtime)
  var pcts = plotN.map(function(n) {
    var vp = getValAt(ep.measurements, n, 'median');
    var vb = getValAt(eb.measurements, n, 'median');
    return (vp && vb) ? (vp / vb) * 100 : null;
  });

  var valid = pcts.filter(function(p) { return p !== null; });
  var minP  = Math.min.apply(null, [0].concat(valid));
  var maxP  = Math.max.apply(null, [150].concat(valid));

  var dotColors = pcts.map(function(p) {
    if (p === null) return '#ccc';
    return isRuntime
      ? (p > 103 ? '#2e7d32' : p < 97 ? '#c62828' : '#888')
      : (p < 97  ? '#2e7d32' : p > 103 ? '#c62828' : '#888');
  });

  var bgColor = isRuntime ? 'white' : '#fdfbff';

  // Green = good side of 100%, red = bad side (reversed for memory).
  var yLo = minP - 5, yHi = maxP + 10;
  var shapes = [
    { type: 'rect', xref: 'paper', yref: 'y', layer: 'below', line: { width: 0 },
      x0: 0, x1: 1,
      y0: isRuntime ? 100 : yLo, y1: isRuntime ? yHi : 100,
      fillcolor: 'rgba(46,125,50,0.10)' },
    { type: 'rect', xref: 'paper', yref: 'y', layer: 'below', line: { width: 0 },
      x0: 0, x1: 1,
      y0: isRuntime ? yLo : 100, y1: isRuntime ? 100 : yHi,
      fillcolor: 'rgba(198,40,40,0.08)' }
  ];

  Plotly.newPlot(el, [
    { x: [plotN[0], plotN[plotN.length - 1]], y: [100, 100],
      type: 'scatter', mode: 'lines',
      line: { dash: 'dot', color: '#888', width: 1.5 },
      showlegend: false, hoverinfo: 'skip' },
    { x: plotN, y: pcts,
      type: 'scatter', mode: 'lines+markers',
      name: sec.primary + ' vs ' + sec.baseline,
      line: { color: '#555', width: 1.5 },
      marker: { size: 6, color: dotColors },
      hovertemplate: '%{y:.1f}%<br>n=%{x}<extra></extra>' }
  ], {
    margin: { t: 8, r: 16, b: 40, l: 50 },
    xaxis: { gridcolor: '#ebebeb' },
    yaxis: {
      gridcolor: '#ebebeb', zeroline: false,
      range: [yLo, yHi], ticksuffix: '%'
    },
    shapes: shapes,
    paper_bgcolor: bgColor, plot_bgcolor: bgColor,
    showlegend: false, hovermode: 'x'
  }, { responsive: true, displayModeBar: false });

  activePlots.push(containerId);
}

// ============================================================
// Controls
// ============================================================

function populateOpSelect() {
  var sec = SECTIONS[state.si];
  var sel = document.getElementById('sel-op');
  sel.innerHTML = '';

  var opt0 = document.createElement('option');
  opt0.value = -1; opt0.textContent = '- Overview -';
  sel.appendChild(opt0);

  // Sort families alphabetically (case-insensitive) for the dropdown,
  // but skip dividers.
  var sorted = sec.families
    .map(function(fam, fi) { return { fam: fam, fi: fi }; })
    .filter(function(x) { return !x.fam.div && !x.fam.noOverview; })  // noOverview = unfair/misleading comparison
    .sort(function(a, b) { return a.fam.label.toLowerCase().localeCompare(b.fam.label.toLowerCase()); });

  sorted.forEach(function(x) {
    var opt = document.createElement('option');
    opt.value = x.fi; opt.textContent = x.fam.label;
    sel.appendChild(opt);
  });

  sel.value = state.fi;
}

function syncControls() {
  document.getElementById('sel-section').value = state.si;
  document.getElementById('sel-op').value      = state.fi;
  document.getElementById('sel-build').value   = state.buildType;
  document.getElementById('sel-metric').value  = state.metric;
}

function initControls() {
  var selSec = document.getElementById('sel-section');
  SECTIONS.forEach(function(sec, i) {
    var opt = document.createElement('option');
    opt.value = i; opt.textContent = sec.label;
    selSec.appendChild(opt);
  });
  selSec.value = state.si;
  selSec.onchange = function() {
    var newSi = parseInt(selSec.value);
    var newFi = -1;
    if (state.fi !== -1) {
      var curId = SECTIONS[state.si].families[state.fi].id;
      var idx   = SECTIONS[newSi].families.findIndex(function(f) { return !f.div && f.id === curId; });
      if (idx !== -1) newFi = idx;
    }
    state.si = newSi;
    state.fi = newFi;
    populateOpSelect();
    pushHistory();
    rerender();
  };

  populateOpSelect();
  document.getElementById('sel-op').onchange = function() {
    state.fi = parseInt(this.value);
    pushHistory();
    rerender();
  };

  var selBuild = document.getElementById('sel-build');
  Object.keys(BUILD_LABELS).filter(function(bt) { return DATA.runtime_data[bt]; })
    .forEach(function(bt) {
      var opt = document.createElement('option');
      opt.value = bt; opt.textContent = BUILD_LABELS[bt];
      if (bt === state.buildType) opt.selected = true;
      selBuild.appendChild(opt);
    });
  selBuild.onchange = function() { state.buildType = selBuild.value; pushHistory(); rerender(); };

  document.getElementById('sel-metric').onchange = function() {
    state.metric = this.value; pushHistory(); rerender();
  };
}

// ============================================================
// Overview
// ============================================================

function renderOverview() {
  purgeCharts();
  syncControls();

  var sec     = SECTIONS[state.si];
  var isRuntime = state.metric === 'runtime';
  var metricLbl = isRuntime ? 'Speed ratio' : 'Memory ratio';
  var dirNote   = isRuntime ? '> 100% = xb5 faster' : '< 100% = xb5 uses less';

  var OV_NS = [100, 300, 1000, 5000];
  var h = '<div class="ov-header">' + metricLbl + '  \u00b7  ' + BUILD_LABELS[state.buildType] + '  \u00b7  ' + dirNote + '</div>';
  h += '<table class="ov-table"><thead><tr>';
  h += '<th>Operation</th>';
  OV_NS.forEach(function(n) { h += '<th class="ov-th-ratio">n=' + n + '</th>'; });
  h += '</tr></thead><tbody>';

  // Collect into sub-groups, sort within each, then emit with dividers intact.
  var subgroups = [];   // [{div, items: [{fam, fi}]}]
  var current = { div: null, items: [] };
  sec.families.forEach(function(fam, fi) {
    if (fam.div) {
      subgroups.push(current);
      current = { div: fam.div, items: [] };
    } else {
      current.items.push({ fam: fam, fi: fi });
    }
  });
  subgroups.push(current);

  subgroups.forEach(function(grp) {
    if (grp.div) {
      h += '<tr class="ov-divider"><td colspan="5">' + grp.div + '</td></tr>';
    }
    grp.items
      .filter(function(x) { return !x.fam.noOverview; })
      .sort(function(a, b) { return a.fam.label.toLowerCase().localeCompare(b.fam.label.toLowerCase()); })
      .forEach(function(x) {
        var fam = x.fam, fi = x.fi;
        h += '<tr><td class="op-name" title="' + fam.id + '" data-fi="' + fi + '">' + fam.label + '</td>';
        if (fam.exclusive) {
          h += '<td colspan="4" style="color:#bbb;font-size:11px;">bag-only</td>';
        } else {
          OV_NS.forEach(function(n) {
            h += '<td class="ov-td-ratio">' + ratioHtml(computeRatio(fam, state.buildType, sec.primary, sec.baseline, n)) + '</td>';
          });
        }
        h += '</tr>';
      });
  });

  h += '</tbody></table>';
  document.getElementById('main').innerHTML = h;

  document.querySelectorAll('.ov-table td.op-name').forEach(function(td) {
    td.onclick = function() {
      state.fi = parseInt(td.dataset.fi);
      populateOpSelect();
      pushHistory();
      renderFamily(state.si, state.fi);
    };
  });
}

// ============================================================
// Family detail
// ============================================================

function renderFamily(si, fi) {
  purgeCharts();
  syncControls();

  var sec = SECTIONS[si];
  var fam = sec.families[fi];
  var s   = getFsel(si, fi);
  var gid = getGroupId(si, fi);

  var entries = gid ? getEntries(state.buildType, gid) : [];
  var hasComp = !fam.exclusive && entries.some(function(e) { return e.impl_mod === sec.baseline; });
  var isRuntime = state.metric === 'runtime';

  // Variant controls
  var ctrlHtml = '';
  if (fam.type === 'param2') {
    var pv = getParam2Variants(fam.id, state.buildType);
    var ovNames = { '000': '0%', '050': '50%', '100': '100%' };
    ctrlHtml += '<div class="ctrl-row">';
    ctrlHtml += '<div class="ctrl-grp2"><label>Overlap</label><div class="btn-grp" id="ctrl-overlaps">';
    pv.overlaps.forEach(function(ov) {
      ctrlHtml += '<button' + (s.overlap === ov ? ' class="active"' : '') +
                  ' data-overlap="' + ov + '">' + (ovNames[ov] || ov) + '</button>';
    });
    ctrlHtml += '</div></div><div class="ctrl-grp2"><label>2nd coll. size</label><div class="btn-grp" id="ctrl-sizes">';
    pv.sizes.forEach(function(sz) {
      ctrlHtml += '<button' + (s.size === sz ? ' class="active"' : '') +
                  ' data-size="' + sz + '">' + parseInt(sz, 10) + '</button>';
    });
    ctrlHtml += '</div></div></div>';
  }
  if (fam.type === 'named') {
    var variants = getNamedVariants(fam.id, state.buildType);
    ctrlHtml += '<div class="ctrl-row"><div class="ctrl-grp2"><label>Variant</label><div class="btn-grp" id="ctrl-variants">';
    variants.forEach(function(v) {
      ctrlHtml += '<button' + (s.variant === v ? ' class="active"' : '') +
                  ' data-variant="' + v.replace(/"/g, '&quot;') + '">' +
                  v.replace(fam.id + ' ', '') + '</button>';
    });
    ctrlHtml += '</div></div></div>';
  }

  var pctLbl = isRuntime
    ? '<span style="color:#666">' + sec.primary + '</span> as % of <span style="color:#666">' + sec.baseline + '</span> speed (100% = same, >100% = xb5 faster)'
    : '<span style="color:#666">' + sec.primary + '</span> as % of <span style="color:#666">' + sec.baseline + '</span> memory (100% = same, <100% = xb5 uses less)';

  var memClass = isRuntime ? '' : ' memory-mode';

  document.getElementById('main').innerHTML =
    '<div class="detail-card' + memClass + '">' +
    '<span class="back-btn" id="back-btn">\u2190 Overview</span>' +
    '<h2>' + fam.label + '</h2>' +
    '<div class="detail-gid">' + (gid || fam.id) + '</div>' +
    '<div class="detail-subtitle">' + sec.label.replace(sec.primary, '<b style="color:#555">' + sec.primary + '</b>').replace(sec.baseline, '<b style="color:#555">' + sec.baseline + '</b>') + '  \u00b7  ' + BUILD_LABELS[state.buildType] + '</div>' +
    ctrlHtml +
    '<div class="chart-lbl">Performance - median with p25\u2013p75 band</div>' +
    '<div class="chart-box" id="main-chart"></div>' +
    (hasComp
      ? '<hr style="border:none;border-top:1px solid #e0e0e0;margin:20px 0 4px"><div class="chart-lbl">' + pctLbl + '</div><div class="pct-box" id="pct-chart"></div>'
      : '<div style="font-size:12px;color:#888;margin-top:10px;">Bag-exclusive - no baseline comparison.</div>') +
    '</div>';

  document.getElementById('back-btn').onclick = function() {
    state.fi = -1;
    populateOpSelect();
    pushHistory();
    renderOverview();
  };

  var elOv = document.getElementById('ctrl-overlaps');
  if (elOv) elOv.querySelectorAll('button').forEach(function(btn) {
    btn.onclick = function() { getFsel(si, fi).overlap = btn.dataset.overlap; renderFamily(si, fi); };
  });
  var elSz = document.getElementById('ctrl-sizes');
  if (elSz) elSz.querySelectorAll('button').forEach(function(btn) {
    btn.onclick = function() { getFsel(si, fi).size = btn.dataset.size; renderFamily(si, fi); };
  });
  var elVr = document.getElementById('ctrl-variants');
  if (elVr) elVr.querySelectorAll('button').forEach(function(btn) {
    btn.onclick = function() { getFsel(si, fi).variant = btn.dataset.variant; renderFamily(si, fi); };
  });

  if (gid) {
    buildMainChart('main-chart', gid, sec);
    if (hasComp) buildPctChart('pct-chart', gid, sec);
  }
}

// ============================================================
// Render dispatcher
// ============================================================

function rerender() {
  if (state.fi === -1) renderOverview();
  else renderFamily(state.si, state.fi);
}

// ============================================================
// Init
// ============================================================

function init() {
  document.getElementById('hdr-title').textContent = PAGE_TITLE;
  var si = DATA.system_info;
  document.getElementById('sysinfo').textContent =
    [si.os, 'Erlang ' + si.erlang, 'Elixir ' + si.elixir,
     si.num_cores + ' cores', si.available_memory,
     si['jit_enabled?'] ? 'JIT \u2713' : 'JIT \u2717'].join(' \u00b7 ');

  var fromHash = hashToState(location.hash);
  if (fromHash) {
    state.si        = fromHash.si;
    state.fi        = fromHash.fi;
    state.buildType = fromHash.buildType;
    state.metric    = fromHash.metric;
  }

  initControls();
  var hash  = stateToHash(state);
  var title = stateTitle(state);
  document.title = title;
  history.replaceState({ si: state.si, fi: state.fi, buildType: state.buildType, metric: state.metric }, title, hash);
  rerender();
}

init();
</script>
</body>
</html>"""

if __name__ == "__main__":
    main()
