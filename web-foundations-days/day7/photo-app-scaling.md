# SnapShare Photo App Scaling Plan

## 1. Assumptions and Daily Active Users

SnapShare is a photo-sharing application where users upload photos and scroll through a feed of photos from people they follow.

### Given facts

* Registered users: 10,000,000
* Daily active users: 10% of registered users
* Uploads per active user: 1 photo per day
* Feed views per active user: 50 pages per day
* Average original photo size: 2 MB
* Average thumbnail size: 50 KB
* Seconds per day: 86,400
* Days per year: 365
* Peak traffic multiplier: 5× average traffic

### Additional assumptions

1. Uploads and feed views are distributed evenly throughout the day for average-rate calculations.
2. Peak traffic is five times the average rate.
3. Every uploaded photo generates one thumbnail.
4. All original photos and thumbnails are retained for one year.
5. Storage estimates exclude backups, database overhead, replication and temporary files.
6. Storage uses decimal units: 1 MB = 1,000 KB and 1 TB = 1,000,000 MB.
7. Each feed page view is counted as one request, excluding additional API requests and individual image downloads.

### Daily active users calculation

Daily active users (DAU) are 10% of the total registered users.

DAU = 10,000,000 × 0.10

DAU = **1,000,000 users per day**

## 2. Traffic and Storage Calculations

### A. Uploads per second

Each daily active user uploads one photo per day.

Daily uploads:

1,000,000 × 1 = 1,000,000 uploads per day

Average uploads per second:

1,000,000 ÷ 86,400 = **11.57 uploads per second**

Peak uploads per second:

11.57 × 5 = **57.87 uploads per second**

The system should therefore plan for approximately 58 photo uploads per second during peak traffic.

### B. Feed views per second

Each daily active user views 50 feed pages per day.

Daily feed views:

1,000,000 × 50 = 50,000,000 feed views per day

Average feed views per second:

50,000,000 ÷ 86,400 = **578.70 feed views per second**

Peak feed views per second:

578.70 × 5 = **2,893.52 feed views per second**

The system should plan for approximately 2,894 feed page requests per second during peak traffic.

### C. Annual photo storage

Each photo consists of an original image and a thumbnail.

Original photo size: 2 MB

Thumbnail size: 50 KB = 0.05 MB

Total storage per uploaded photo:

2 MB + 0.05 MB = 2.05 MB

Daily original photo storage:

1,000,000 × 2 MB = 2,000,000 MB = 2 TB per day

Daily thumbnail storage:

1,000,000 × 0.05 MB = 50,000 MB = 0.05 TB per day

Total daily storage:

2 TB + 0.05 TB = 2.05 TB per day

Annual original photo storage:

2 TB × 365 = 730 TB per year

Annual thumbnail storage:

0.05 TB × 365 = 18.25 TB per year

Total annual storage:

730 TB + 18.25 TB = **748.25 TB per year**

This is the estimated storage required for one year's uploads, excluding backups, replicas, metadata and other overhead.

### Calculation summary

| Metric                             | Estimated value |
| ---------------------------------- | --------------: |
| Registered users                   |      10,000,000 |
| Daily active users                 |       1,000,000 |
| Daily uploads                      |       1,000,000 |
| Average uploads per second         |           11.57 |
| Peak uploads per second            |           57.87 |
| Daily feed views                   |      50,000,000 |
| Average feed views per second      |          578.70 |
| Peak feed views per second         |        2,893.52 |
| Daily photo and thumbnail storage  |         2.05 TB |
| Annual photo and thumbnail storage |       748.25 TB |

## 3. Read-Heavy or Write-Heavy?

SnapShare is a **read-heavy system** because users view 50 feed pages for every photo they upload.

The application processes 50 million feed page views per day compared with 1 million photo uploads per day. This is a ratio of 50 feed views per upload.

The architecture should prioritise fast feed retrieval and image delivery while keeping database reads manageable.

The design uses:

* A CDN to deliver cached photos and thumbnails.
* A cache to reduce repeated database queries for popular feed data.
* A database read replica to handle suitable read queries.
* Multiple app servers behind a load balancer to distribute application traffic.
* Object storage to handle large photo files independently of the database.
* A message queue and background worker to generate thumbnails asynchronously.

Writes still require reliable handling, but read optimisation is the primary scaling concern.

## 4. Why Photos Belong in Object Storage

Photo files should be stored in object storage rather than directly inside database tables.

Photos are large binary files, and storing them in the database would increase database size, make backups and restores more expensive, and consume resources needed for queries and transactions.

Object storage is designed to store large volumes of files and scale independently of the database.

SnapShare can use object storage for original photos and generated thumbnails, while the database stores their metadata.

The database stores information such as:

* Photo ID and uploader ID
* Object storage key for the original photo
* Object storage key for the thumbnail
* Caption and upload timestamp
* Visibility and processing status

This separation allows photo storage to scale independently while keeping database records smaller and easier to query.

## 5. Architecture Diagram

```text
                         +------------------+
                         |      Users       |
                         +--------+---------+
                                  |
                                  v
                         +------------------+
                         |       CDN        |
                         | Cached Images    |
                         +--------+---------+
                                  |
                                  v
                         +------------------+
                         |  Load Balancer   |
                         +--------+---------+
                                  |
                    +-------------+-------------+
                    |             |             |
                    v             v             v
              +-----------+ +-----------+ +-----------+
              | App Server| | App Server| | App Server|
              +-----+-----+ +-----+-----+ +-----+-----+
                    |             |             |
                    +-------------+-------------+
                                  |
                         +--------+--------+
                         |                 |
                         v                 v
                  +------------+    +-------------+
                  | Cache      |    | Main        |
                  | Feed/Data  |    | Database    |
                  +------------+    | (Primary)   |
                                    +------+------+
                                           |
                                           | Replication
                                           v
                                    +-------------+
                                    | Read Replica|
                                    +-------------+

              Upload processing:

              +-------------+       +----------------+
              | App Server  |------>| Object Storage |
              |             |       | Original Photos|
              +------+------+       +----------------+
                     |
                     v
              +-------------+
              | Message     |
              | Queue       |
              +------+------+
                     |
                     v
              +-------------+
              | Thumbnail   |
              | Worker      |
              +------+------+
                     |
                     v
              +----------------+
              | Object Storage |
              | Thumbnails     |
              +----------------+
```

The diagram represents the logical architecture. The CDN serves cached images directly when possible, while the load balancer routes application requests to healthy app servers.

## 6. Component Descriptions

1. **CDN:** Delivers cached photos and thumbnails from distributed edge locations, reducing latency and the load on origin storage.

2. **Load balancer:** Distributes incoming application requests across healthy app servers to prevent a single server from becoming overloaded.

3. **App servers:** Handle authentication, uploads, feed requests, follow relationships and application logic, and can scale horizontally by adding more instances.

4. **Cache:** Stores frequently requested feed data and other reusable results in memory to reduce database queries and improve response times.

5. **Main database (primary):** Stores authoritative application records, including users, photo metadata and follow relationships, and handles database writes.

6. **Database read replica:** Receives replicated data from the primary database and serves suitable read queries, reducing the read workload on the primary.

7. **Object storage:** Stores original photos and thumbnails as files, allowing large image storage to grow independently of the database.

8. **Message queue:** Holds thumbnail-generation jobs until workers can process them, absorbing bursts of uploads without forcing users to wait for image processing.

9. **Thumbnail worker:** Processes queued jobs, generates smaller versions of original photos and stores the resulting thumbnails in object storage.

## 7. Photo Upload Flow

1. **User selects a photo:** The user chooses an image and submits it through the SnapShare interface.

2. **Request reaches the load balancer:** The load balancer forwards the upload request to a healthy app server.

3. **Authentication and validation:** The app server verifies the user's identity and checks the file type, size and other upload requirements.

4. **Original photo is stored:** The app server uploads the original image to object storage and obtains its storage key.

5. **Metadata is saved:** The app server records the photo ID, uploader ID, storage key, caption, timestamp and thumbnail processing status in the primary database.

6. **Thumbnail job is queued:** The app server publishes a job containing the photo ID and original storage key to the message queue.

7. **Upload is acknowledged:** Once the original photo and required metadata are safely saved and the thumbnail job is durably queued, the app server confirms the upload without waiting for thumbnail generation.

8. **Worker retrieves the job:** A thumbnail worker consumes the queued job and retrieves the original image from object storage.

9. **Thumbnail is generated:** The worker resizes the original image to produce a thumbnail, targeting an average size of 50 KB.

10. **Thumbnail is saved:** The worker stores the thumbnail in object storage and records its storage key or updates the photo's processing status in the database.

11. **CDN delivers the image:** When users view the photo in a feed, the CDN serves the thumbnail if cached; otherwise, it retrieves the image from the configured origin.

### Upload reliability

Object storage, the database and the message queue do not share a single transaction, so the application must handle partial failures.

The design should use retryable jobs, idempotent thumbnail processing, monitoring and cleanup for orphaned files or incomplete uploads. If thumbnail generation fails, the system should retry the job and show a placeholder until the thumbnail is available.

## 8. Trade-Offs

### Trade-off 1: Caching versus data freshness

**Benefit:** Caching popular feed data reduces database load and improves response times.

**Cost:** Users may temporarily see outdated feed results after a photo is deleted or a follow relationship changes.

**Decision:** Use appropriate cache expiration periods and invalidate affected entries after important updates.

### Trade-off 2: Read replicas versus consistency

**Benefit:** Read replicas allow the system to handle more database reads without overloading the primary database.

**Cost:** Replication lag can cause recently uploaded photos or updated profile details to appear late in some reads.

**Decision:** Use the primary database for operations requiring immediate consistency and replicas for reads that can tolerate a short delay.

### Trade-off 3: Asynchronous processing versus immediate availability

**Benefit:** A message queue and background workers allow uploads to complete without waiting for thumbnails, improving the user experience and absorbing bursts of work.

**Cost:** Thumbnails may not be available immediately, and queue processing introduces additional infrastructure and failure-handling requirements.

**Decision:** Track thumbnail status, retry failed jobs and display a placeholder while processing is pending.

### Trade-off 4: Object storage versus simpler database management

**Benefit:** Object storage scales independently and is designed for large numbers of files.

**Cost:** The application must coordinate file storage, metadata records, permissions and cleanup when uploads fail or photos are deleted.

**Decision:** Store image bytes in object storage and metadata in the database, with retry and cleanup mechanisms to handle partial failures.

## Conclusion

SnapShare has an estimated 1 million daily active users, 11.57 average photo uploads per second and 578.70 average feed views per second. Applying the 5× peak multiplier gives approximately 58 uploads and 2,894 feed views per second.

Original photos and thumbnails require approximately **748.25 TB of storage per year**, before backups and other overhead.

A scalable design separates image storage from database metadata, uses a CDN and cache to improve feed performance, distributes application requests across multiple app servers, offloads suitable database reads to a replica, and processes thumbnails asynchronously through a queue and background worker.

These components provide a foundation for scaling SnapShare while balancing performance, consistency, reliability and operational complexity.
