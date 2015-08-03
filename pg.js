var pg = require('pg');
var fs = require('fs');
var Util = require('./pg-util.js');
var settings = require('../settings').pg;

// PostGIS Connection String
var conString = "postgres://" +
    settings.user + ":" +
    settings.password + "@" +
    settings.server + ":" +
    settings.port + "/" +
    settings.database;

/**
 * Main query function to execute an SQL query.
 *
 * @type {Function}
 */
var query = module.exports.query = function(queryStr, cb) {
  pg.connect(conString, function(err, client, done) {
    if(err) {
      console.error('error fetching client from pool', err);
    }
    client.query(queryStr, function(queryerr, result) {
      done();
      if(queryerr) {
        console.error('ERROR RUNNING QUERY:', queryStr, queryerr);
      }
      cb((err || queryerr), (result && result.rows ? result.rows : result));
    });
  });
};
