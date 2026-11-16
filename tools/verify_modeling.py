"""Public metafor fixtures plus independent SciPy likelihood optimization.
Run after moon build --target js --release; development dependencies only.
"""
import copy, json, math, pathlib, random, subprocess, tempfile
import numpy as np
from scipy.optimize import minimize_scalar
from scipy.stats import norm, t
ROOT = pathlib.Path(__file__).resolve().parents[1]
MAX_ERROR = 0.0
FITS = 0
ERRORS = 0

def close(actual, expected, tol=8e-6):
    global MAX_ERROR
    error = abs(actual-expected)/max(1.0, abs(expected))
    MAX_ERROR = max(MAX_ERROR, error)
    assert math.isfinite(actual) and error <= tol, (actual, expected, error, tol)

def run(q, ok=True):
    with tempfile.TemporaryDirectory() as d:
        p = pathlib.Path(d)/'request.json'
        p.write_text(json.dumps(q), encoding='utf-8')
        result = subprocess.run(['node',str(ROOT/'tools/synthesis.mjs'),str(p)],
                                capture_output=True,text=True,encoding='utf-8',timeout=30)
    assert result.returncode == 0, (result.returncode,result.stderr,result.stdout)
    response = json.loads(result.stdout)
    assert response['ok'] == ok, response
    if not ok:
        assert 'results' not in response
        return response
    return response['results']

def rows(y, v):
    return [dict(id=f's{i}',effect=float(a),variance=float(b)) for i,(a,b) in enumerate(zip(y,v))]

def independent(y, v, mods):
    X = np.column_stack([np.ones(len(y)), mods])
    scale = float(min(v)); ys = y/math.sqrt(scale); vs = v/scale
    def wls(tau):
        w = 1/(vs+tau)
        beta = np.linalg.lstsq(X*np.sqrt(w)[:,None], ys*np.sqrt(w),rcond=None)[0]
        residual = ys-X@beta
        cov = np.linalg.inv((X.T*w)@X)
        q = float(np.dot(w,residual**2))
        _, logdet = np.linalg.slogdet((X.T*w)@X)
        objective = float(np.log(vs+tau).sum()+logdet+q)
        return objective, beta, cov, q
    # An independent likelihood objective (not the MoonBit score solver).
    high = max(1.0,float(np.var(ys,ddof=1))*4)
    opt = minimize_scalar(lambda tau:wls(tau)[0],bounds=(0,high),method='bounded',
                          options={'xatol':1e-12,'maxiter':2000})
    assert opt.success
    tau = 0.0 if wls(0)[0] <= opt.fun else float(opt.x)
    _, beta, cov, q = wls(tau)
    return tau*scale, beta*math.sqrt(scale), cov*scale, q, wls(0)[3]

def verify_fit(actual, tau, beta, cov, q, qe, inference, alpha, count):
    df = count-len(beta)
    factor = max(1,q/df) if inference=='modified-hk' else 1
    cov = cov*factor
    critical = t.isf(alpha/2,df) if inference=='modified-hk' else norm.isf(alpha/2)
    close(actual['tau2'],tau)
    close(actual['residual_q'],q)
    close(actual['residual_heterogeneity_q'],qe)
    assert actual['residual_df']==df and actual['model']=='REML'
    for j,b in enumerate(beta):
        se = math.sqrt(cov[j,j]); a=actual['coefficients'][j]
        close(a['estimate'],b); close(a['standard_error'],se)
        close(a['confidence']['lower'],b-critical*se)
        close(a['confidence']['upper'],b+critical*se)
        for l in range(len(beta)): close(actual['covariance'][j][l],cov[j,l])
    return cov

fixture = json.loads((ROOT/'fixtures/metafor-bcg/reference.json').read_text(encoding='utf-8'))
d = fixture['data']; public_max = 0.0
for label,names,pred in [('intercept',[],[[]]),('latitude',['ablat'],[[13],[30],[55]]),
                         ('multi',['ablat','year'],[[13,1950],[30,1970],[55,1980]])]:
    for inference,test in [('normal','z'),('modified-hk','adhoc')]:
        # Raw two-arm counts exercise the actual log-RR input route, not only
        # precomputed effect values from the numerical reference.
        studies = [dict(id=str(a['trial']),kind='log-rr',
            treatment=dict(events=a['tpos'],total=a['tpos']+a['tneg']),
            control=dict(events=a['cpos'],total=a['cpos']+a['cneg'])) for a in d]
        request = dict(version=2,studies=studies,names=names,
                       moderators=[[a[n] for n in names] for a in d],
                       inference=inference,predict=pred)
        out=run(request); a=out['regression']; r=fixture['fits'][label+'_'+test]
        # metafor covariance already includes the adhoc scale factor.
        beta=np.atleast_1d(r['beta']);cov=np.array(r['covariance']);
        verify_fit(a,r['tau2'],beta,cov,r['residual_q'],r['QE'],'normal',0.05,len(d)) if inference=='normal' else None
        critical=t.isf(.025,a['residual_df']) if test=='adhoc' else norm.isf(.025)
        close(a['tau2'],r['tau2'],2e-8);close(a['residual_q'],r['residual_q'],2e-8)
        close(a['residual_heterogeneity_q'],r['QE'],2e-8)
        for j,b in enumerate(beta):
            aa=a['coefficients'][j]
            for key,expect in [('estimate',b),('standard_error',np.atleast_1d(r['se'])[j])]:close(aa[key],expect,2e-8)
            close(aa['confidence']['lower'],np.atleast_1d(r['ci_lower'])[j],3e-6)
            close(aa['confidence']['upper'],np.atleast_1d(r['ci_upper'])[j],3e-6)
            for l in range(len(beta)):close(a['covariance'][j][l],cov[j,l],2e-8)
        rp=r['prediction']
        for j,row in enumerate(pred):
            ap=out['predictions'][j]
            close(ap['estimate'],np.atleast_1d(rp['estimate'])[j],2e-8)
            close(ap['standard_error'],np.atleast_1d(rp['se'])[j],2e-8)
            close(ap['confidence']['lower'],np.atleast_1d(rp['ci_lower'])[j],3e-6)
            close(ap['confidence']['upper'],np.atleast_1d(rp['ci_upper'])[j],3e-6)
            x=np.array([1,*row]);variance=float(x@cov@x)
            radius=t.isf(.025,a['residual_df']-1)*math.sqrt(r['tau2']+variance)
            close(ap['prediction']['lower'],float(x@beta)-radius,3e-6)
            close(ap['prediction']['upper'],float(x@beta)+radius,3e-6)
        FITS+=1
public_max=MAX_ERROR
rng=np.random.default_rng(20261116)
for case in range(60):
    k=5+case%19; m=case%4
    mod=rng.normal(size=(k,m))
    scale=10.0**((case%7)-3)
    v=scale*scale*rng.uniform(.05,2,k)
    y=scale*(rng.normal(size=k)*(case%5)+mod@rng.normal(size=m)+.2)
    if case%10==0:y=np.full(k,.3*scale)
    tau,beta,cov,q,qe=independent(y,v,mod)
    for inference in ['normal','modified-hk']:
        request=dict(version=2,studies=rows(y,v),names=[f'x{i}' for i in range(m)],
                     moderators=mod.tolist(),inference=inference,alpha=.1,predict=[np.zeros(m).tolist()])
        out=run(request);a=out['regression']
        adj=verify_fit(a,tau,beta,cov,q,qe,inference,.1,k)
        ap=out['predictions'][0];close(ap['estimate'],beta[0]);close(ap['standard_error'],math.sqrt(adj[0,0]))
        FITS+=1
    if m==0:
        out=run(dict(version=1,model='reml',inference='normal',studies=rows(y,v)))['summary']
        close(out['pool']['tau2'],tau);close(out['pool']['estimate'],beta[0]);close(out['pool']['variance'],cov[0,0]);FITS+=1
# Shape/name/rank/policy errors must be atomic across the public CLI.
base=dict(version=2,studies=rows([0,1,2,3],[1,1,1,1]),names=['x'],moderators=[[0],[1],[2],[3]],predict=[[1]])
bad=[]
for field,val in [('names',['intercept']),('names',['']),('moderators',[[0],[1]]),('moderators',[[1],[1],[1],[1]]),
                  ('moderators',[[0,1],[1,1],[2,1],[3,1]]),('predict',[[1,2]]),('model','fixed'),('alpha',0),('extra',True)]:
    q=copy.deepcopy(base);q[field]=val;bad.append(q)
q=copy.deepcopy(base);q['names']=['x','y'];q['moderators']=[[0,0],[1,2],[2,4],[3,6]];q['predict']=[];bad.append(q)
q=copy.deepcopy(base);q['names']=['x','x'];q['moderators']=[[0,0],[1,1],[2,4],[3,9]];q['predict']=[];bad.append(q)
q=copy.deepcopy(base);q['predict']=[[1]]*129;bad.append(q)
for q in bad:run(q,False);ERRORS+=1
# The new intercept model also reaches all existing sensitivity/report routes.
q=json.loads((ROOT/'examples/request.json').read_text(encoding='utf-8'));q['model']='reml'
r=run(q)
assert len(r['leave-one-out'])==4 and r['cumulative'][-1]['analysis']==r['summary']
assert r['summary']['model']=='REML' and len(r['subgroups']['groups'])==2
assert len(r['csv'])>0 and '<svg' in r['svg']
print(json.dumps(dict(public_metafor_fits=6,independent_scipy_fits=FITS-6,rejected_requests=ERRORS,
    max_scaled_error=MAX_ERROR,public_max_scaled_error=public_max,seed=20261116)))
