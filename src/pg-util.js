var fs = require('fs');
var settings = require('../settings.js').pg;

var Util = {};
var sqlFiles = {};

Util.sanitize = function(val) {
  // we want a null to still be null, not a string
  if (typeof val === 'string' && val !== 'null') {
    // $nh9$ is using $$ with an arbitrary tag. $$ in pg is a safe way to quote something,
    // because all escape characters are ignored inside of it.
    var esc = settings.escapeStr;
    return "$"+esc+"$" + val + "$"+esc+"$";
  }
  return val;
};

Util.sqlTemplate = function(sqlFile, tplHash) {
  var sql = sqlFiles[sqlFile];
  if (!sql) {
    sqlFiles[sqlFile] = sql = fs.readFileSync(sqlFile, 'utf8');
  }
  if (tplHash) {
    for (var key in tplHash) {
      var exp = '{{' + key + '}}';
      var regex = new RegExp(exp, 'g');
      var val = tplHash[key];
      sql = sql.replace(regex, val);
    }
  }
  return sql;
};

module.exports = Util;
