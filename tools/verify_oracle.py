"""Independent differential checks. Run after a release JS build; no runtime dependencies."""
import json, math, pathlib, random, subprocess, tempfile
import numpy as np
from scipy.stats import norm, t
from statsmodels.stats.meta_analysis import combine_effects, effectsize_smd, effectsize_2proportions
ROOT = pathlib.Path(__file__).resolve().parents[1]
CASES = 0
MAX_ERROR = 0.0

def close(actual, expected, tolerance=2e-8):
    global MAX_ERROR
    error = abs(actual - expected) / max(1.0, abs(expected))
    MAX_ERROR = max(MAX_ERROR, error)
    assert math.isfinite(actual) and error <= tolerance, (actual, expected, error)

def run(request):
    with tempfile.TemporaryDirectory() as directory:
        path = pathlib.Path(directory) / 'input.json'
        path.write_text(json.dumps(request), encoding='utf-8')
        process = subprocess.run(['node', str(ROOT/'tools/synthesis.mjs'), str(path)],
                                 capture_output=True, text=True, encoding='utf-8', timeout=30)
    assert process.returncode == 0, process.stderr
    response = json.loads(process.stdout)
    assert response['ok'], response
    return response['results']

def reference(y, v, model):
    # statsmodels DL permits negative tau²; our documented estimator truncates it.
    fit = combine_effects(y, v, method_re='iterated' if model == 'pm' else 'chi2',
                          **({'atol': 1e-12, 'maxiter': 200} if model == 'pm' else {}))
    tau = 0.0 if model == 'fixed' else max(0.0, fit.tau2)
    weights = 1.0/(v+tau)
    mean = np.dot(weights, y)/weights.sum()
    variance = 1.0/weights.sum()
    residual = np.dot(weights, (y-mean)**2)
    return fit, tau, weights/weights.sum(), mean, variance, residual

def check(y, v, model, inference, raw=None):
    global CASES
    request = dict(version=1, model=model, inference=inference, outputs=['summary','studies'],
                   studies=raw or [dict(id=f's{i}', effect=float(a), variance=float(b)) for i,(a,b) in enumerate(zip(y,v))])
    result = run(request)
    actual = result['summary']
    fit, tau, weights, mean, variance, residual = reference(y, v, model)
    close(actual['pool']['tau2'], tau)
    close(actual['pool']['estimate'], mean)
    close(actual['pool']['variance'], variance)
    close(actual['pool']['residual_q'], residual)
    close(actual['heterogeneity']['q'], fit.q)
    close(actual['heterogeneity']['i2'], max(0.0, 1-(len(y)-1)/fit.q) if fit.q > 0 else 0.0)
    factor = max(1.0, residual/(len(y)-1)) if inference == 'modified-hk' else 1.0
    se = math.sqrt(variance*factor)
    critical = t.isf(0.025, len(y)-1) if inference == 'modified-hk' else norm.isf(0.025)
    close(actual['standard_error'], se)
    # MoonBit's compact normal CDF approximation has a documented quantile tolerance.
    close(actual['confidence']['lower'], mean-critical*se, 3e-6)
    close(actual['confidence']['upper'], mean+critical*se, 3e-6)
    if model == 'fixed' or len(y) == 2:
        assert actual['prediction'] is None
    else:
        radius = t.isf(0.025, len(y)-2)*math.sqrt(tau+se*se)
        close(actual['prediction']['lower'], mean-radius, 3e-6)
        close(actual['prediction']['upper'], mean+radius, 3e-6)
    for i, row in enumerate(result['studies']):
        close(row['effect'], float(y[i]))
        close(row['variance'], float(v[i]))
        close(row['weight'], float(weights[i]))
    CASES += 1

rng = random.Random(20261111)
datasets = [(np.array([1.,1.,1.]), np.array([.1,.2,.3]))]
for i in range(35):
    k = 2 + i % 10
    scale = 10.0**((i%7)-3)
    y = np.array([rng.gauss(0, scale) for _ in range(k)])
    v = np.array([scale*scale*rng.uniform(.05, 2) for _ in range(k)])
    datasets.append((y,v))
for y,v in datasets:
    for model,inference in [('fixed','normal'),('dl','normal'),('dl','modified-hk'),('pm','normal'),('pm','modified-hk')]:
        check(y,v,model,inference)
for i in range(12):
    nt = np.array([20+i, 30+i, 40+i])
    nc = np.array([25+i, 35+i, 45+i])
    mt = np.array([1.2+i*.01, 2.3, 3.1])
    mc = np.array([1., 2., 3.])
    st = np.array([1., 1.3, 1.5])
    sc = np.array([1.1, 1.4, 1.6])
    for kind in ['md','hedges-g']:
        raw = [dict(kind=kind,id=f's{j}',treatment=dict(n=int(nt[j]),mean=float(mt[j]),sd=float(st[j])),
                    control=dict(n=int(nc[j]),mean=float(mc[j]),sd=float(sc[j]))) for j in range(3)]
        y,v = (mt-mc,st*st/nt+sc*sc/nc) if kind=='md' else effectsize_smd(mt,st,nt,mc,sc,nc)
        check(y,v,'pm','modified-hk',raw)
    et,ec = np.array([3+i,7+i,9+i]),np.array([6+i,9+i,11+i])
    for kind,statistic in [('log-or','or'),('log-rr','rr')]:
        raw = [dict(kind=kind,id=f's{j}',treatment=dict(events=int(et[j]),total=int(nt[j])),
                    control=dict(events=int(ec[j]),total=int(nc[j]))) for j in range(3)]
        y,v = effectsize_2proportions(et,nt,ec,nc,statistic=statistic)
        check(y,v,'dl','normal',raw)
print(json.dumps(dict(reference='statsmodels 0.14.5 / scipy 1.16.2',
                      dataset_fits=CASES, max_scaled_error=MAX_ERROR, seed=20261111)))
