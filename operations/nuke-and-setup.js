var pg = require('pg');
var Q = require('q');
var fs = require('fs');
var exec = require('child_process').exec;

// Get DB settings for the requested environment
var settings = require('../settings.js').local;

// build DB connection string
var conString = "postgres://" +
    settings.user + ":" +
    settings.password + "@" +
    settings.server + ":" +
    settings.port + "/" +
    settings.database;

/**
 * This destroys the current database and recreates a
 * fresh one with no tables or functions added yet...
 */
function nukeDB() {

    var deferred = Q.defer();

    var db = settings.database;
    var kill = 'psql -d ' + db + ' -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = \'' + db
        + '\' AND pid <> pg_backend_pid()";';
    var drop = 'dropdb ' + db;
    var create = 'createdb ' + db + ' -O ' + settings.user;

    exec(kill, function(error, stdout, stderr) {

        exec(drop, function(error, stdout, stderr) {
            if (stderr) console.error(stderr);

            exec(create, function (error, stdout, stderr) {
                if (stderr) {
                    console.error(stderr);
                    return deferred.reject(stderr);
                }

                else {
                    console.log('db nuked and recreated.');
                    return deferred.resolve(true)
                }

            });
        });
    });

    return deferred.promise;
}


function runDeferredPsql(command){

    var deferred = Q.defer();

    exec(command, function (error, stdout, stderr) {
        if (stderr) {
            console.error(stderr);
            return deferred.reject(stderr);
        }

        else {
            console.log('success.');
            return deferred.resolve(true)
        }

    });

    return deferred.promise;

}
/**
 * Query function to execute an SQL query against Postgres DB.
 *
 * @type {Function}
 */
function query(queryStr) {

    var deferred = Q.defer();

    pg.connect(conString, function(err, client, done) {
        if(err) {
            console.error('error fetching client from pool', err);
        }
        client.query(queryStr, function(queryerr, result) {

            done();

            if(queryerr) {
                //console.error('ERROR RUNNING QUERY:', queryStr, queryerr);
                deferred.reject(queryerr);
            } else {
                deferred.resolve(result && result.rows ? result.rows : result);
            }

        });
    });

    return deferred.promise;
}

/*
 var q1 = fs.readFileSync('node_modules/cadasta-db/sql/1_db.sql', 'utf8');
 var q2 = fs.readFileSync('node_modules/cadasta-db/sql/2_field-data-tables.sql');
 var q3 = fs.readFileSync('node_modules/cadasta-db/sql/3_db-functions.sql');
 var q4 = fs.readFileSync('node_modules/cadasta-db/sql/4_db-views.sql');
 var q5 = fs.readFileSync('node_modules/cadasta-db/sql/5_validation-functions.sql');
 var q6 = fs.readFileSync(__dirname + '/truncate-db-tables.sql', 'utf8');
 */
return nukeDB()

    .then(function(response){
        return runDeferredPsql('psql -U ' + settings.user + ' -d ' + settings.database + ' -q -f ../sql/1_db.sql');

    })
    .then(function(){

        console.log('1_db.sql complete.');
        return runDeferredPsql('psql -U ' + settings.user + ' -d ' + settings.database + ' -q -f ../sql/2_field-data-tables.sql');

    })
    .then(function(){

        console.log('2_survey-tables.sql complete.');
        return runDeferredPsql('psql -U ' + settings.user + ' -d ' + settings.database + ' -q -f ../sql/3_db-functions.sql');


    })
    .then(function(){

        console.log('3_db-functions.sql complete.');
        return runDeferredPsql('psql -U ' + settings.user + ' -d ' + settings.database + ' -q -f ../sql/4_db-views.sql');

    })
    .then(function(){
        console.log("4_db-view is complete.")
        return runDeferredPsql('psql -U ' + settings.user + ' -d ' + settings.database + ' -q -f ../sql/5_validation-functions.sql');

    })
    .then(function(){
        console.log("5_validation-functions.sql is complete.")
        return runDeferredPsql('psql -U ' + settings.user + ' -d ' + settings.database + ' -q -f ../sql/6_test-data.sql');

    })

    .then(function(){

        console.log('6_test-data.sql is complete.');
        return runDeferredPsql('psql -U ' + settings.user + ' -d ' + settings.database + ' -q -f ../sql/truncate-db-tables.sql');


    })
    .then(function(){

        console.log('truncate function is complete.');
        return ;

    })
    .catch(function(err){
        console.log(err);
    })
    .done();