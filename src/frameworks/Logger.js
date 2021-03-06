/**
 * @description Structured logging helper
 */
class Logger {
  constructor(projectId, loggingComponent) {
    this.projectId = projectId || process.env.GOOGLE_CLOUD_PROJECT;
    this.loggingComponent = loggingComponent || process.env.LOGGING_COMPONENT;
  }

  log({ message, severity = 'NOTICE', error = undefined }, traceHeader = undefined) {
    try {
      const globalLogFields = {};

      // Add tracing header if we have one (we should have one if within GCP)
      if (traceHeader) {
        const [trace] = traceHeader.split('/');
        globalLogFields[
          'logging.googleapis.com/trace'
        ] = `projects/${this.projectId}/traces/${trace}`;
      }

      const entry = Object.assign(
        {
          severity,
          message,
          error,
          component: this.loggingComponent
        },
        globalLogFields
      );

      console.log(JSON.stringify(entry));
    } catch (error) {
      console.error(error);
    }
  }
}

module.exports = { Logger };
