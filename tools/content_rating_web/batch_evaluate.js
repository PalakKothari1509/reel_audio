const http = require('http');

function test(path, method, body) {
  return new Promise((resolve, reject) => {
    const opts = { hostname: 'localhost', port: 3000, path, method, headers: {} };
    if (body) {
      opts.headers['Content-Type'] = 'application/json';
      opts.headers['Content-Length'] = Buffer.byteLength(body);
    }
    const req = http.request(opts, r => {
      let d = '';
      r.on('data', c => d += c);
      r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', e => reject(e));
    if (body) req.write(body);
    req.end();
  });
}

async function evaluateAll() {
  // First get all ideas
  const ideasRes = await test('/api/ideas', 'GET');
  const ideasData = JSON.parse(ideasRes.body);
  const ideas = ideasData.ideas;
  console.log('Total ideas to evaluate:', ideas.length);

  const results = [];
  let successCount = 0;
  let failCount = 0;

  for (let i = 0; i < ideas.length; i++) {
    const ideaId = ideas[i].id;
    try {
      const res = await test(`/api/evaluate/${ideaId}`, 'POST', JSON.stringify({ mode: 'offline' }));
      const result = JSON.parse(res.body);
      results.push(result);
      
      if (res.status === 200) {
        successCount++;
        console.log(`[${i+1}/117] ${ideaId}: Score ${result.overallScore} — ${result.verdict}`);
      } else {
        failCount++;
        console.log(`[${i+1}/117] ${ideaId}: ERROR ${res.status}`);
      }
    } catch (e) {
      failCount++;
      console.log(`[${i+1}/117] ${ideaId}: EXCEPTION ${e.message}`);
    }
    
    // Small delay to avoid overwhelming server
    await new Promise(r => setTimeout(r, 50));
  }

  console.log('\n=== BATCH EVALUATION COMPLETE ===');
  console.log('Total evaluated:', results.length);
  console.log('Successful:', successCount);
  console.log('Failed:', failCount);

  // Save results to file
  const fs = require('fs');
  fs.writeFileSync('re_evaluation_results.json', JSON.stringify(results, null, 2));
  console.log('Results saved to re_evaluation_results.json');

  // Summary stats
  const ready = results.filter(r => r.verdict === 'Ready to Post').length;
  const minor = results.filter(r => r.verdict === 'Needs Minor Fixes').length;
  const major = results.filter(r => r.verdict === 'Needs Major Rewrite').length;
  const reject = results.filter(r => r.verdict === 'Reject').length;
  console.log('\nVerdict distribution:');
  console.log(`  Ready to Post: ${ready}`);
  console.log(`  Needs Minor Fixes: ${minor}`);
  console.log(`  Needs Major Rewrite: ${major}`);
  console.log(`  Reject: ${reject}`);

  return results;
}

evaluateAll().catch(e => console.error('Fatal error:', e));
