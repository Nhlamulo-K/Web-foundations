# TicketHub: Ticketing System Design

## 1. Requirements

### Functional Requirements
- Users can register, log in, browse events and view seat availability.
- Users can hold seats, pay for tickets and view orders.
- Administrators can manage events, seats and sales.

### Non-Functional Requirements
- **Speed:** Pages load within two seconds under normal conditions.
- **Correctness:** A seat cannot be sold to multiple customers.
- **Fairness:** Queues and rate limits control high demand and discourage bots.
- **Scalability:** Services handle sudden traffic increases.
- **Security:** User data is protected and payments use a secure provider.
- **Reliability:** Failures do not lose confirmed orders.

## 2. Traffic Estimates

### Normal Traffic
- Visitors: 50,000 per day.
- Page views: 50,000 × 10 = 500,000 per day.
- Average page views: 500,000 ÷ 86,400 ≈ **5.8 per second**.
- Average visitors: 50,000 ÷ 86,400 ≈ **0.58 per second**.
- Tickets sold: 5,000 per day, or approximately 0.058 per second.

### Popular Concert Sale
- Buyers: 200,000 in 10 minutes.
- Average arrival rate: 200,000 ÷ 600 ≈ **333 people per second**.
- Available seats: 20,000.
- Competition: 10 buyers per seat.
- Required sales rate to sell all seats in 10 minutes: 20,000 ÷ 600 ≈ **33 tickets per second**.

The concert sale has approximately 576 times the normal average visitor arrival rate. Actual peak traffic may be higher, so queues, caching and scalable services are necessary.

| Measurement | Normal day | Popular sale |
|---|---|---|
| Visitors | 50,000 per day | 200,000 in 10 minutes |
| Average arrival rate | 0.58 people/second | 333 people/second |
| Tickets | 5,000 sold | 20,000 available |

## 3. API Design

TicketHub uses a REST API with HTTPS and JSON.

| Method and endpoint | Purpose |
|---|---|
| `GET /api/events` | Browse events |
| `GET /api/events/{eventId}/seats` | View seat availability |
| `POST /api/seat-holds` | Hold available seats |
| `POST /api/orders` | Create an order |
| `POST /api/orders/{orderId}/payment` | Initiate payment |
| `POST /api/payment-webhooks` | Receive payment updates |
| `GET /api/me/tickets` | View purchased tickets |

Authenticated endpoints require a valid session or token. Unavailable seats return `409 Conflict`, while rate-limited requests return `429 Too Many Requests`. Idempotency keys prevent payment retries from creating duplicate charges or orders.

## 4. Data Model

PostgreSQL stores related records and supports transactions.

### Main Tables
- **Users:** `id` (PK), `name`, `email` (unique), `password_hash`.
- **Events:** `id` (PK), `name`, `venue`, `starts_at`, `status`.
- **Seats:** `id` (PK), `event_id` (FK), `section`, `row_label`, `seat_number`, `price`, `status`, `hold_expires_at`.
- **Orders:** `id` (PK), `user_id` (FK), `event_id` (FK), `total_amount`, `status`, `created_at`.
- **Seat Holds:** `id` (PK), `user_id` (FK), `event_id` (FK), `expires_at`, `status`.
- **Order Items:** `id` (PK), `order_id` (FK), `seat_id` (FK), `unit_price`.

### Relationships and Constraints
- A user can have many orders and holds.
- An event has many seats and orders.
- An order contains one or more order items.
- Each order item references a specific seat.

Foreign keys maintain relationships. A unique constraint on event, section, row and seat number prevents duplicate seat records. Database constraints and transactional checks prevent the same seat from being sold twice.

## 5. Preventing Double-Booking

TicketHub uses database transactions, row locks and constraints to protect seat ownership.

1. The server starts a transaction and locks the requested seat rows.
2. It checks availability and creates a five-minute hold.
3. Competing requests wait or recheck availability. Unavailable seats return `409 Conflict`.
4. After verified payment confirmation, a transaction marks the order as paid and the seat as sold.
5. Expired unpaid holds are released so other customers can purchase those seats.

Payment webhooks must be verified and processed idempotently. Failed or delayed payments require explicit order-state handling and hold-expiry rules. The database, not the browser's seat map, determines final availability.

## 6. Architecture

```text
Web / Mobile App
       |
 CDN / Rate Limits
       |
 Waiting Queue
       |
 API Gateway
       |
 +-----+------+
 |            |
Event API   Hold / Order API
 |            |
Cache      PostgreSQL
              |
       Payment Provider
```

### Component Responsibilities
- **CDN:** Caches static content and reduces server load.
- **Waiting Queue:** Controls admission during high-demand sales.
- **API Gateway:** Routes requests and enforces authentication and rate limits.
- **Event API and Cache:** Serve event information efficiently.
- **Hold / Order API:** Manages holds, orders and payment workflows.
- **PostgreSQL:** Stores seats and orders and enforces transactional consistency.
- **Payment Provider:** Processes payments securely and sends payment updates.

During a popular sale, the queue limits incoming requests, caching reduces database reads, and additional API instances handle increased demand. Database transactions protect seat ownership, while monitoring and load testing reveal capacity problems.

## 7. System Trade-Offs

### 7.1 Consistency versus Speed
Transactions and row locks prevent double-booking but may slow requests during heavy competition. TicketHub prioritises correct purchases over accepting unsafe requests.

### 7.2 Fairness versus Immediate Access
A waiting queue controls overload and orders admission, but customers must wait. Rate limits and bot detection help improve fairness, although a queue alone cannot guarantee it.

### 7.3 Temporary Holds versus Availability
Five-minute holds give customers time to pay but temporarily block other buyers. Reliable expiry and release processes prevent seats from remaining unavailable unnecessarily.

### 7.4 Caching versus Fresh Data
Caching improves browsing speed but cached availability may become outdated. TicketHub rechecks seat availability in PostgreSQL before confirming a hold.

## Conclusion

TicketHub combines a waiting queue, scalable APIs, caching, PostgreSQL transactions and secure payment processing to handle normal traffic and concert-sale peaks. Its key priority is ensuring that each seat can be purchased by only one customer.
