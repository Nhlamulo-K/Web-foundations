# SnapShare: Photo App Scaling Plan

## Assumptions and daily users
A photo-sharing app where users upload photos and scroll a feed of photos from people they follow.

- Ten per cent of registered users are active each day.
- Each daily active user uploads exactly one photo and views 50 feed pages.
- Uploads and feed views are spread evenly across the day when calculating average rates.
- Peak traffic is five times the average traffic.
- Each uploaded photo produces one thumbnail.
- Every photo and thumbnail is retained for one year, with no deletions or compression beyond the stated sizes.
- Calculations exclude database overhead, backups, replication, temporary files and other application data.
- Storage estimates use decimal units: 1 MB = 1,000 KB and 1 GB = 1,000 MB.

#### Daily active users
Daily Active Users ​= 10,000,000×0.10 = 1,000,000

## Traffic and storage calculations
- Uploads per second: 
    - Each of the 1 million daily active users uploads one photo per day.
    - Uploads per day= 1,000,000 × 1 =1,000,000

- Average uploads per second:
    - 86,400 / 1,000,000 = 11.57

- Peak uploads per second:
    - 11.57 × 5 = 57.87

- Feed views per second
    - Each active user views 50 feed pages per day.

    - Feed views per day= 1,000,000 × 50 = 50,000,000

- Average feed views per second:
    - 86,400 / 50,000,000 = 578.70

- Peak feed views per second:
    - 578.70 × 5 = 2,893.52