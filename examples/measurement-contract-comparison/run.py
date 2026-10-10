"""Execute unchanged published JS/Rust sources against ten labelled fixtures.

No package downloads, no network calls, no PHP arithmetic invented. Python,
Node.js and a working Rust/Cargo toolchain must already be installed.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent

def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))

def verify_sources():
    lock = read_json(HERE / 'source-lock.json')
    for row in lock['files']:
        path = HERE / row['path']
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != row['sha256'] or len(data) != row['bytes']:
            raise RuntimeError('Source snapshot changed: ' + row['path'])
    return lock

def tool_path(value):
    resolved = shutil.which(value)
    if resolved:
        return resolved
    path = Path(value)
    if path.is_file():
        return str(path.resolve())
    raise RuntimeError('Required runtime unavailable: ' + value)

def execute(command, timeout=120):
    return subprocess.run(command, cwd=HERE, capture_output=True, text=True, encoding='utf-8', errors='strict', timeout=timeout)

def rust_command(c, executable):
    v = c['input']
    def length(n, unit):
        return repr(n) + unit
    if c['operation'] == 'convert':
        return [executable, 'convert', length(v['value'], v['from']), v['to']]
    units = v['units']
    if c['operation'] == 'stretch':
        return [executable, 'stretch', *(length(v[key], units[i]) for i, key in enumerate(['original','stretched','released']))]
    return [executable, 'print-scale', *(length(v[key], units[i]) for i, key in enumerate(['target','measured_x','measured_y'])), repr(v['tolerance_percent'])]

def rust_evaluate(c, executable):
    completed = execute(rust_command(c, executable), 15)
    base = {'case_id':c['id'], 'engine':'rust', 'native_call_performed':True}
    if completed.returncode == 2:
        return {**base, 'status':'rejected', 'error':completed.stderr.strip(), 'native_exit_code':2}
    if completed.returncode != 0:
        raise RuntimeError('Rust execution failed unexpectedly for ' + c['id'])
    raw = json.loads(completed.stdout)
    if c['operation'] == 'convert':
        value = {'converted_length':raw['value']}
    elif c['operation'] == 'stretch':
        value = {k:raw[k] for k in ['stretch_percent','residual_change_percent','recovered_extension_percent','unusual_released_length']}
    else:
        value = {k:raw[k] for k in ['x_error_percent','y_error_percent','difference_percentage_points','non_uniform','within_tolerance']}
    return {**base, 'status':'accepted', 'value':value, 'native_output':raw, 'native_exit_code':0}

def compare_values(actual, expected, prefix):
    failures = []
    for key, value in expected.items():
        got = actual.get(key)
        if isinstance(value, bool) or value is None:
            valid = got is value
        elif isinstance(value, (int, float)):
            valid = isinstance(got, (int, float)) and not isinstance(got, bool) and math.isfinite(got)
            # Zero expectations are exact: a positive underflow result is not hidden.
            valid = valid and (got == 0 if value == 0 else math.isclose(got, value, rel_tol=1e-12, abs_tol=1e-12))
        else:
            valid = got == value
        if not valid:
            failures.append(f'{prefix}.{key}: observed {got!r}, expected {value!r}')
    return failures

def check_rows(cases, rows):
    expected_ids = {(c['id'], engine) for c in cases for engine in ['npm','drupal_js','rust']}
    seen = {(r['case_id'],r['engine']) for r in rows}
    if len(rows) != len(expected_ids) or seen != expected_ids:
        raise RuntimeError('Each fixture must have exactly one result from each implementation')
    by_id = {c['id']:c for c in cases}
    failures = []
    for row in rows:
        expected = by_id[row['case_id']]['expected'][row['engine']]
        label = row['case_id'] + '/' + row['engine']
        if row['status'] != expected['status']:
            failures.append(label + ': unexpected outcome status')
        if 'value' in expected:
            failures.extend(compare_values(row.get('value', {}), expected['value'], label))
        if 'error_code' in expected and row.get('error_code') != expected['error_code']:
            failures.append(label + ': unexpected error code')
        if 'error_contains' in expected and expected['error_contains'] not in row.get('error', ''):
            failures.append(label + ': unexpected error reason')
        called = row.get('native_call_performed')
        if called is not (expected['status'] != 'unsupported'):
            failures.append(label + ': inconsistent native call evidence')
    return failures

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--node', default='node')
    parser.add_argument('--cargo', default='cargo')
    parser.add_argument('--write', action='store_true', help='Save the actual deterministic output to results/observed.json')
    args = parser.parse_args()
    lock = verify_sources()
    cases = read_json(HERE / 'cases.json')
    if len(cases) != 10 or not all(c.get('synthetic_software_fixture') is True for c in cases):
        raise RuntimeError('Exactly ten disclosed synthetic software fixtures required')
    node = tool_path(args.node)
    cargo = tool_path(args.cargo)
    target = HERE / '.work/rust-target'
    built = execute([cargo, 'build', '--offline', '--locked', '--release', '--manifest-path', str(HERE / 'vendor/rust/Cargo.toml'), '--target-dir', str(target)])
    if built.returncode != 0:
        raise RuntimeError('Offline Rust build failed; no Rust execution success claimed\n' + built.stderr)
    binary = target / 'release' / ('sewlore-measure.exe' if os.name == 'nt' else 'sewlore-measure')
    if not binary.is_file():
        raise RuntimeError('Actual Rust CLI binary missing after build')
    rows = []
    for engine in ['npm','drupal_js']:
        ran = execute([node, str(HERE / 'adapters/javascript.mjs'), engine], 15)
        if ran.returncode != 0:
            raise RuntimeError('JavaScript adapter failed: ' + engine + '\n' + ran.stderr)
        rows.extend(json.loads(ran.stdout))
    rows.extend(rust_evaluate(c, str(binary)) for c in cases)
    rows.sort(key=lambda r: (r['case_id'], ['npm','drupal_js','rust'].index(r['engine'])))
    failures = check_rows(cases, rows)
    report = {'schema':'sewlore-contract-comparison-results-v1', 'fixtures':10, 'physical_measurement_records':0, 'result_records':len(rows), 'native_arithmetic_calls':sum(r['native_call_performed'] for r in rows), 'outcomes':dict(sorted(Counter(r['status'] for r in rows).items())), 'expectation_check':'pass' if not failures else 'fail', 'unexplained_differences':failures, 'PHP_numeric_execution_claimed':False, 'source_files_SHA256_verified':len(lock['files']), 'numeric_comparison':{'relative_tolerance':1e-12,'absolute_tolerance':1e-12,'zero_expectations':'exact'}, 'results':rows}
    if args.write:
        (HERE / 'results').mkdir(exist_ok=True)
        (HERE / 'results/observed.json').write_text(json.dumps(report, indent=2, allow_nan=False) + '\n', encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k != 'results'}, indent=2))
    return 1 if failures else 0

if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(2)
