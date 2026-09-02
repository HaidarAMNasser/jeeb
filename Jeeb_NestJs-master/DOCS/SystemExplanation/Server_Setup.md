# Server Setup & Configuration

## 1. Environment Configuration (.env)

The server configuration is managed through the `.env` file in the root directory.

### Port Configuration

To change the port the server listens on, update the `PORT` variable:

```env
PORT=3000  # Default is 3000
```

### Database Host (PostgreSQL)

To configure the database connection host:

```env
DB_HOST=localhost # or your database IP
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=your_password
DB_NAME=jeeb_db
```

### Redis Configuration

Redis is required for OTP storage and BullMQ (Job Queues).

#### 1. Running Redis on Windows

Since Redis is not natively supported on Windows, you have two options:

**Option A: Using Docker (Recommended)**
If you have Docker Desktop installed, run:

```bash
docker-compose up -d redis
```

**Option B: Using Memurai (Redis for Windows)**

1. Download and install **Memurai Developer Edition** (<https://www.memurai.com/>).
2. It will run automatically as a Windows Service on port `6379`.

**Option C: Using WSL (Windows Subsystem for Linux)**

1. Open your Ubuntu/Debian terminal in WSL.
2. Run: `sudo apt-get install redis-server`.
3. Start it: `sudo service redis-server start`.

#### 2. Configuration (.env)

Ensure your `.env` file matches your running Redis instance:

```env
REDIS_HOST=localhost
REDIS_PORT=6379
```

### Email Configuration (SMTP)

Configure your SMTP provider for email notifications:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
```

## 2. Running the Server

### Development Mode

To start the server in development mode with hot-reload (restarts automatically on file changes):

```bash
npm run start:dev
```

### Production Mode

To build and run the server in production mode:

```bash
npm run build
npm run start:prod
```

### Debug Mode

To run in debug mode:

```bash
npm run start:debug
```

## 3. Verifying the Server is Running

Once started, you should see logs indicating the server is listening:

```
[Nest] ... Nest application successfully started
[Nest] ... Server running on http://localhost:3000
```

## 4. Background Services

### BullMQ (Job Queues)

- The server automatically connects to Redis to manage job queues.
- Ensure Redis is running before starting the application.
- Used for: Order Timeout (15 mins).

### Cron Jobs

- Scheduled tasks run automatically based on the system time.
- Ensure the server time is correctly configured.
- Used for: Daily cleanup of old notification logs.
