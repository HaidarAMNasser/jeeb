module.exports = (() => {
  require('dotenv').config({ path: process.cwd() + '/.env.production' });

  const PORT = process.env.PORT || 3000;
  const cwdPath = '/root/var/www/src_v1/Jeeb_NestJs';

  return {
    apps: [
      {
        name: 'delivery-jeeb',
        script: cwdPath + '/dist/src/main.js',
        cwd: cwdPath,
        instances: 'max',
        exec_mode: 'cluster',
        autorestart: true,
        watch: false,
        max_memory_restart: '1G',
        // Security settings
        max_restarts: 10,
        min_uptime: '10s',
        wait_ready: true,
        kill_timeout: 5000,
        // Error logging
        error_file: cwdPath + '/logs/pm2-error.log',
        out_file: cwdPath + '/logs/pm2-out.log',
        log_file: cwdPath + '/logs/pm2-combined.log',
        time: true,
        env: {
          NODE_ENV: 'production',
          PORT: PORT,
          DB_HOST: process.env.DB_HOST || 'localhost',
          DB_PORT: parseInt(process.env.DB_PORT) || 5432,
          DB_USERNAME: process.env.DB_USERNAME || 'jeeb_user',
          DB_PASSWORD: process.env.DB_PASSWORD || 'StrongPassword123',
          DB_DATABASE: process.env.DB_DATABASE || 'jeeb_db',
          REDIS_HOST: process.env.REDIS_HOST || 'localhost',
          REDIS_PORT: parseInt(process.env.REDIS_PORT) || 6379,
          JWT_SECRET: process.env.JWT_SECRET,
          FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID,
          FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY,
          FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL,
          FIREBASE_DATABASE_URL: process.env.FIREBASE_DATABASE_URL,
        },
      },
    ],
  };
})();
