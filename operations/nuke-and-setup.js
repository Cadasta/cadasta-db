/**
 * This operation destroys the database in the settings file
 * and builds a new one ready for data ingestion.
 *
 * Note: if you are having problems running this, try
 * closing pgAdmin3.
 */

var pgSetup = require('../src/pg-setup.js');

pgSetup.nukeDB(pgSetup.setupDB);
