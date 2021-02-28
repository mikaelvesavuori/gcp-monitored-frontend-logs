const fastify = require('fastify')({ logger: true });
const fastifyCors = require('fastify-cors');
const { ErrorReporting } = require('@google-cloud/error-reporting');

const { Logger } = require('./frameworks/Logger');

// Vars; EDIT THESE TO YOUR VALUES
const PORT = process.env.PORT || 8080;
const PROJECT_ID = process.env.PROJECT_ID || 'frontend-logs-1234';
const LOGGING_COMPONENT = process.env.LOGGING_COMPONENT || 'errors-my-project'; // Your "category" or "container" for the logs

// Local use
//const KEYFILE_PATH = process.env.KEYFILE_PATH || '/Users/YOUR_NAME/.gcp/keyfile.json';

// Set up GCP Error Reporting
const config = {
  projectId: PROJECT_ID,
  reportMode: 'always' // Use 'always' for shipping logs while in development
  // Local use
  //credentials: require(KEYFILE_PATH)
};
const errors = new ErrorReporting(config);

// Set up logging utility
const logger = new Logger(PROJECT_ID, LOGGING_COMPONENT);

// Add CORS to Fastify
fastify.register(fastifyCors, {});

/**
 * @description Our API endpoint which will create logs based on what came in from the front-end
 */
fastify.post('/', async (req, res) => {
  const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  const { message, severity, error } = body;
  console.log(body);
  if (!message || !severity)
    return res.code(500).send(JSON.stringify('Missing message or severity!'));

  try {
    // Add tracing header if we have one (we should have one if within GCP)
    const traceHeader =
      req.headers['x-cloud-trace-context'] || req.headers['X-Cloud-Trace-Context'];

    // Clean stack trace from newlines
    let stackTrace = error ? error.replace(/\n/g, '') : null;

    // Create a structured log
    logger.log(
      {
        message,
        severity,
        error: stackTrace
      },
      traceHeader
    );

    // Pass error to Error Reporting
    errors.report(error);
    return res.code(200).send('OK');
  } catch (error) {
    return res.code(500).send(JSON.stringify(error));
  }
});

const start = async () => {
  try {
    await fastify.listen(PORT, '0.0.0.0');
    fastify.log.info(`server listening on ${fastify.server.address().port}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
