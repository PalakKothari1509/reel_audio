
const { openDb, dbAll, closeDb } = require('./tools/content_rating_web/backend/db.js');

try {
  openDb();
  const results = dbAll(`SELECT * FROM evaluations`);
  console.log(JSON.stringify(results, null, 2));
} finally {
  closeDb();
}