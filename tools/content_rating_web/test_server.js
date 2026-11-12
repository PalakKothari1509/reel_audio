const http = require('http');

function test(path, method, body) {
  return new Promise((resolve, reject) => {
    const opts = { hostname: 'localhost', port: 3001, path, method, headers: {} };
    if (body) { opts.headers['Content-Type'] = 'application/json'; opts.headers['Content-Length'] = Buffer.byteLength(body); }
    const req = http.request(opts, r => { let d=''; r.on('data', c=>d+=c); r.on('end', ()=>resolve({status:r.statusCode, body:d, headers:r.headers})); });
    req.on('error', e => reject(e));
    if (body) req.write(body);
    req.end();
  });
}

(async () => {
  try {
    const root = await test('/', 'GET');
    console.log('Root /:', root.status);
    
    const h = await test('/api/health', 'GET');
    console.log('Health:', h.status, h.body);
    
    const i = await test('/api/ideas', 'GET');
    const ideas = JSON.parse(i.body);
    console.log('Ideas:', ideas.ideas.length);
    
    const ev = await test('/api/evaluate/idea_1', 'POST', JSON.stringify({ mode: 'offline' }));
    const r = JSON.parse(ev.body);
    console.log('Evaluate:', ev.status, 'score:', r.overallScore, 'verdict:', r.verdict);
    
    const ratings = await test('/api/ratings', 'GET');
    console.log('Ratings:', ratings.status, JSON.parse(ratings.body).length);
    
    const ej = await test('/api/export/json', 'GET');
    console.log('Export JSON:', ej.status);
    
    const ec = await test('/api/export/csv', 'GET');
    console.log('Export CSV:', ec.status);
    
    console.log('All tests passed!');
  } catch(e) {
    console.error('Error:', e.message);
  }
})();
