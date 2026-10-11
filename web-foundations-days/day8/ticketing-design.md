# TicketHub: Ticketing System Design

## 1. Requirements

### Functional Requirements
- Users can register, log in, browse events, and view seat availability.
- Users can temporarily hold seats, pay for tickets, and view their orders.
- Administrators can create events, manage seats, and monitor sales.

### Non-Functional Requirements
- **Speed:** Pages should load within two seconds under normal conditions.
- **Correctness:** A seat must never be sold to two customers.
- **Fairness:** A waiting queue and rate limits should manage high demand and discourage bots.
- **Scalability:** The system must handle sudden traffic increases.
- **Security:** Protect user information and use a secure payment provider.
- **Reliability:** Recover from failures without losing confirmed orders.

## 2. Traffic Estimates

### Normal Traffic
- Visitors: 50,000 per day.
- Page views: 50,000 × 10 = **500,000 per day**.
- Average page views per second: 500,000 ÷ 86,400 ≈ **5.8**.
- Tickets sold: 5,000 per day.
- Average sales rate: 5,000 ÷ 86,400 ≈ **0.058 tickets per second**.

### Popular Concert Sale
- Buyers: 200,000 in 10 minutes.
- Average arrival rate: 200,000 ÷ 600 = **333 people per second**.
- Available seats: 20,000.
- Competition: 200,000 ÷ 20,000 = **10 people per seat**.
- Sales rate needed to sell all seats in 10 minutes: 20,000 ÷ 600 ≈ **33 tickets per second**.

| Measurement | Normal Day | Popular Sale |
|---|---|---|
| Visitors | 50,000 per day | 200,000 in 10 minutes |
| Average arrival rate | 0.58 people/second | 333 people/second |
| Tickets | 5,000 sold | 20,000 available |

The popular sale's average arrival rate is approximately 576 times the normal daily average. A waiting queue, caching, and scalable services will help handle this demand. Actual peak traffic may be higher than the average.

## 3. API Design

TicketHub will use a REST API with HTTPS and JSON.

| Method and Endpoint | Purpose |
|---|---|
| `GET /api/events` | Browse events |
| `GET /api/events/{eventId}/seats` | View seats and availability |
| `POST /api/seat-holds` | Temporarily hold available seats |
| `POST /api/orders` | Create an order |
| `POST /api/orders/{orderId}/payment` | Initiate payment |
| `POST /api/payment-webhooks` | Receive payment confirmation |
| `GET /api/me/tickets` | View purchased tickets |

Authenticated requests require a valid user session or token. A seat that becomes unavailable returns `409 Conflict`. Rate-limited requests return `429 Too Many Requests`.

Payment requests must be processed safely so retries do not create duplicate charges or orders.

## 4. Data Model

TicketHub will use PostgreSQL to store related data and support transactions.

### Main Tables

**Users**
- `id` — primary key
- `name`
- `email` — unique
- `password_hash`

**Events**
- `id` — primary key
- `name`
- `venue`
- `starts_at`
- `status`

**Seats**
- `id` — primary key
- `event_id` — foreign key to Events
- `section`
- `row_label`
- `seat_number`
- `price`
- `status` — available, held, or sold
- `hold_expires_at`

A unique constraint on event, section, row, and seat number prevents duplicate seat records.

**Orders**
- `id` — primary key
- `user_id` — foreign key to Users
- `event_id` — foreign key to Events
- `total_amount`
- `status`
- `created_at`

**Seat Holds**
- `id` — primary key
- `user_id` — foreign key to Users
- `event_id` — foreign key to Events
- `expires_at`
- `status`

**Order Items**
- `id` — primary key
- `order_id` — foreign key to Orders
- `seat_id` — foreign key to Seats
- `unit_price`

### Relationships

- One user can have many orders and seat holds.
- One event can have many seats and orders.
- One order can contain multiple order items.
- Each order item references a specific seat.

Foreign keys maintain relationships, while unique constraints prevent duplicate seat identifiers and duplicate confirmed ticket sales.

## 5. Preventing Double-Booking

TicketHub uses **database transactions, row locks, and constraints** to ensure that only one customer can claim a seat.

1. When a customer requests a seat, the server starts a database transaction and locks the relevant seat rows.
2. The server checks availability and creates a temporary hold lasting five minutes.
3. If another customer tries to claim the same seat, the database makes that request wait or recheck availability. The second customer receives `409 Conflict` if the seat is already held.
4. If payment succeeds, a transaction marks the order as paid and the seat as sold.
5. If the hold expires without a successful purchase, the seat can be released for another customer.

Unique constraints provide an additional safeguard against duplicate sales. Payment notifications must also be verified and processed idempotently to prevent repeated requests from creating duplicate orders.

The database, rather than the seat map displayed in the browser, makes the final decision about seat availability.

## 6. Architecture Diagram

```text
       ┌─────────────────┐
       │ Web / Mobile App│
       └────────┬────────┘
                ▼
       ┌─────────────────┐
       │ CDN + Rate Limit│
       └────────┬────────┘
                ▼
       ┌─────────────────┐
       │ Waiting Queue   │
       └────────┬────────┘
                ▼
       ┌─────────────────┐
       │ API Gateway     │
       └────┬────────┬───┘
            ▼        ▼
       ┌─────────┐ ┌───────────┐
       │ Event   │ │ Hold and  │
       │ API     │ │ Order API │
       └────┬────┘ └─────┬─────┘
            ▼            ▼
       ┌─────────┐ ┌───────────┐
       │ Cache   │ │ PostgreSQL│
       └─────────┘ └─────┬─────┘
                         ▼
                   ┌───────────┐
                   │ Payment   │
                   │ Provider  │
                   └───────────┘
```

### Component Explanations

- **CDN:** Serves static content and reduces load on the backend.
- **Waiting queue:** Controls how many customers enter the purchasing system.
- **API gateway:** Routes requests and applies authentication and rate limits.
- **Event API and cache:** Handle browsing requests efficiently.
- **Hold and order API:** Manages seat reservations and purchases.
- **PostgreSQL:** Stores authoritative seat and order data and prevents double-booking through transactions and constraints.
- **Payment provider:** Processes payments securely and sends confirmation to TicketHub.

During a popular sale, the queue controls incoming traffic, cached event information reduces database requests, and additional API instances can handle more users. Database transactions protect seat ownership, while monitoring and load testing help identify capacity problems.

## 7. Trade-Offs

### Consistency versus Speed
Database transactions prevent double-booking but can slow requests when many customers compete for the same seats. TicketHub prioritises correct purchases over accepting unsafe requests.

### Fairness versus Immediate Access
A waiting queue makes customers wait, but it reduces overload and gives the system more control over high-demand sales.

### Temporary Holds versus Availability
Five-minute holds give customers time to pay but temporarily prevent others from buying those seats. Expired holds must be released reliably.

### Caching versus Fresh Data
Caching speeds up event browsing, but availability can change quickly. TicketHub therefore checks seat availability again when creating a hold.

## Conclusion

TicketHub combines a waiting queue, scalable APIs, PostgreSQL transactions, and secure payment processing to handle normal traffic and popular concert sales. Its most important safeguard is ensuring that only one customer can successfully reserve and purchase each seat.
