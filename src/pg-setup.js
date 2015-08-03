var pg = require('./pg.js');
var fs = require('fs');
var Util = require('./pg-util.js');
var settings = require('../settings.js').pg;
var exec = require('child_process').exec;

/**
 * This destroys the current database and recreates a
 * fresh one with no tables or functions added yet...
 */
function nukeDB(cb) {
  var db = settings.database;
  var kill = 'psql -d ' + db + ' -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = \'' + db + '\'";';
  var drop = 'dropdb ' + db;
  var create = 'createdb ' + db + ' -O ' + settings.user;

  exec(kill, function(error, stdout, stderr) {
    exec(drop, function(error, stdout, stderr) {
      if (stderr) console.error(stderr);
      exec(create, function (error, stdout, stderr) {
        if (stderr) console.error(stderr);
        else console.log('db nuked and recreated.');
        if (typeof cb === 'function') {
          cb();
        }
      });
    });
  });
}

function setupDB() {
  var q1 = fs.readFileSync('../sql/1_db.sql', 'utf8');
  var q2 = fs.readFileSync('../sql/2_survey-tables.sql', 'utf8');

  pg.query(q1, function () {
    console.log('../sql/1_db.sql complete.');
    pg.query(q2, function() {
      console.log('../sql/2_survey-tables.sql complete.');

      // Templates in the postgres user in this SQL script.
      // Functions should have user in settings as owner.

        // not running 3, we will be having a node version of this instead
      //var q3 = Util.sqlTemplate('../sql/3_db-functions.sql', {user: settings.user});
      //pg.query(q3, function () {
      //  console.log('../sql/3_db-functions.sql complete.');
      //});

    });
  });
}

module.exports = {
  nukeDB: nukeDB,
  setupDB: setupDB
};
