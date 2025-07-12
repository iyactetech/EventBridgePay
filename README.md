
# Payment API

A comprehensive Node.js Express API for payment processing with PostgreSQL database, Docker Compose setup, and automated reconciliation.

## Features

- **Payment Processing**: `/pay` endpoint to simulate bill payments
- **Webhook Handling**: `/webhook` endpoint for provider callbacks
- **PostgreSQL Database**: Full database integration with migrations
- **Docker Compose**: Complete containerized setup
- **Cron Jobs**: Automated reconciliation scheduling
- **Error Handling**: Comprehensive error management
- **Request Logging**: Morgan-based request logging
- **Health Checks**: Database connectivity monitoring


## Why These Components  Matter.?
/pay -->  Accepts and initiates payment logic ---> No new payments, lost revenue if it fails

/webhook -->  Updates transaction status from provider ---> Inaccurate records, user complaints  if it fails

Cron Job --> Fallback for missed webhooks/status fetch --> Unresolved/undetected failures



## Quick Start

### Using Docker Compose (Recommended)

1. **Start the services:**
   docker compose up -d 
            or
   docker compose up -d --build
   

2. **Check service status:**
   docker compose ps

3. **View logs:**
   docker-compose logs -f api



## API Endpoints

### Simulating "Process a Payment" (/pay)
curl -X POST http://localhost:3000/api/payments/pay \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.00,
    "customer_id": "test_customer",
    "description": "Test payment from DevOps"
  }'

#### expected output
A successful HTTP 2xx response from the API, possibly with a JSON payload indicating the new payment ID and status.


### Simulating "Check Payment Stats" (/stats)
curl http://localhost:3000/api/payments/stats

#### expected output
 A successful HTTP 2xx response, with a JSON payload containing actual statistics (e.g., total payments, completed payments count).


 ### Simulate Webhook Callback

#### Create a payload.json
cat > payload.json <<EOF
{"event_type":"payment.completed","payment_id":"<replace-with-id-from-Simulating-"Process-a-Payment">","provider":"test_provider","data":{"reference":"<reference-from-from-Simulating-"Process-a-Payment">"}}1
EOF

#### expected output
a payload.json file will be created in your project


#### Check payment Stats
curl http://localhost:3000/api/payments/stats

#### expected output
A successful HTTP 2xx response,


### Generate the HMAC signature from exactly that file and Send the exact same file with curl 
signature=$(openssl dgst -sha256 -hmac "webhook-secret-key" payload.json | awk '{print $2}')
echo "Signature: $signature"

curl -X POST http://localhost:3000/api/webhooks \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: $signature" \
  --data-binary "@payload.json"

#### Why is this Super Important?
- Because you need to generate the HMAC signature from the exact payload.json file and send that same file using --data-binary to ensure the raw body bytes match exactly.

- This is important because HMAC signing is very sensitive to changes — even a single space, newline, or key order difference will result in a different signature, and the server will reject it as invalid.

#### expected output
A successful HTTP 2xx response,  in  JSON indicating server successfully received, verified, and processed the webhook.




## Database Schema

### Tables

- **payments**: Store payment records
- **webhooks**: Track webhook events
- **reconciliation_logs**: Log reconciliation runs

### Key Features

- UUID primary keys
- Automatic timestamps
- JSONB metadata support
- Proper indexing
- Foreign key constraints

## Reconciliation

The system includes automated reconciliation that:

- Runs every hour (production)
- Runs every 5 minutes (demo)
- Checks pending payments against provider
- Updates payment statuses
- Logs all reconciliation activities



## Environment Variables

```env
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=payment_api
DB_USER=admin
DB_PASSWORD=password123

# Security
API_SECRET=your-secret-key-here
WEBHOOK_SECRET=webhook-secret-key
```


## Architecture

```
Dockerfile
|
README.me
|
docker-compose.yml
|
package-lock.json
|
package.json
src/
├── config/          # Database configuration
├── controllers/     # Request handlers
├── jobs/           # Cron jobs and background tasks
├── middleware/     # Express middleware
├── migrations/     # Database migrations
├── models/         # Data models
├── routes/         # API routes
├── services/       # Business logic
└── server.js       # Application entry point
```



## Production Considerations

1. **Security**: Update all secret keys and passwords
2. **Database**: Use managed PostgreSQL service
3. **Monitoring**: Add application monitoring
4. **Logging**: Configure structured logging
5. **Rate Limiting**: Add API rate limiting
6. **SSL/TLS**: Enable HTTPS
7. **Backup**: Configure database backups



## Development

### Adding New Features

1. Create models in `src/models/`
2. Add business logic in `src/services/`
3. Create controllers in `src/controllers/`
4. Define routes in `src/routes/`
5. Add migrations in `src/migrations/`

### Database Migrations

Create new migration files in `src/migrations/` and run:

```bash
npm run migrate
```

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL status
docker compose logs postgres

# Reset database
docker compose down -v
docker compose up -d
```

### API Issues

```bash
# Check API logs
docker-compose logs api

# Restart API service
docker-compose restart api
```

## License

MIT License



# Challenges I encountered in this Project

#### 1. Signature was always invalid
I discovered that when using `curl -d`, the payload was being reformatted (adding/removing whitespace), which broke the signature verification.

**Fix**:
I switched to using `--data-binary` to send the raw JSON without formatting:

```bash
curl -X POST http://localhost:3000/api/webhooks \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: <signature>" \
  --data-binary "@payload.json"
```

---

####  2. Signature was undefined (empty)
This happened because the `WEBHOOK_SECRET` environment variable wasn't loaded inside the container.

**Fix**:
I added it to my `.env` file and ensured Docker loaded it by including:

```env
WEBHOOK_SECRET=webhook-secret-key
```

Then passed it in `docker-compose.yml`:

```yaml
env_file:
  - .env
```

---

####  3. TypeError: Cannot read properties of undefined (processWebhookEvent)
I used `this.processWebhookEvent(...)` inside a static method, which doesn’t work.

**Fix**:
I changed it to call the method directly from the class:

```js
await WebhookController.processWebhookEvent(webhook);
```

---

####  4. Signature mismatch despite correct JSON
Even though my JSON looked correct, `curl -d` was silently modifying the formatting, which affected the signature.

**Fix**:
I used this instead:

```bash
--data-binary "@payload.json"
```

---

####  5. Raw body was missing in Express

My server was parsing JSON normally, but to verify the webhook signature, I needed access to the unmodified raw body.

**Fix**:
I added a custom `verify` function only for the webhook route:

```js
app.use('/api/webhooks', express.json({
  verify: (req, res, buf) => {
    req.rawBody = buf.toString('utf8');
  }
}));
```

</details>



