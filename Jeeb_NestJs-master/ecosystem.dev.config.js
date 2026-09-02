module.exports = (() => {
  require('dotenv').config({ path: __dirname + '/.env' });

  const PORT = process.env.PORT || 3001;
  const cwdPath = '/root/var/www/src_test';

  return {
    apps: [
      {
        name: 'delivery-jeeb-dev',
        script: cwdPath + '/dist/src/main.js',
        cwd: cwdPath,
        instances: 'max',
        exec_mode: 'cluster',
        autorestart: true,
        watch: false,
        max_memory_restart: '1G',
        max_restarts: 10,
        min_uptime: '10s',
        wait_ready: true,
        kill_timeout: 5000,
        error_file: cwdPath + '/logs/pm2-error.log',
        out_file: cwdPath + '/logs/pm2-out.log',
        log_file: cwdPath + '/logs/pm2-combined.log',
        time: true,
        env: {
          NODE_ENV: 'development',
          PORT: PORT,
          DB_HOST: process.env.DB_HOST || 'localhost',
          DB_PORT: parseInt(process.env.DB_PORT) || 5432,
          DB_USERNAME: process.env.DB_USERNAME || 'jeeb_dev_user',
          DB_PASSWORD: process.env.DB_PASSWORD || 'StrongPassword123Dev',
          DB_DATABASE: process.env.DB_DATABASE || 'jeeb_db_dev',
          REDIS_HOST: process.env.REDIS_HOST || 'localhost',
          REDIS_PORT: parseInt(process.env.REDIS_PORT) || 6379,
          JWT_SECRET: process.env.JWT_SECRET,
          FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID,
          FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY,
          FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL,
          FIREBASE_DATABASE_URL: process.env.FIREBASE_DATABASE_URL,
          DISABLE_TOKEN_REVOCATION: 'true',
          THROTTLER_DEFAULT_LIMIT: '999999',
          THROTTLER_GET_LIMIT: '999999',
          THROTTLER_LONG_LIMIT: '999999',
        },
      },
    ],
  };
})();
