# Empire Sync

A Ruby on Rails application that syncs Empire Flippers marketplace listings to HubSpot as Deal objects on a daily basis.

## What It Does

- Fetches all **"For Sale"** listings from the Empire Flippers public API once per day
- Stores listing data in a PostgreSQL database
- Creates **Deal objects in HubSpot** for each listing
- Updates existing HubSpot deals when listing data changes (price, summary)
- Prevents duplicate deals from being created

## Tech Stack

- **Ruby on Rails**
- **PostgreSQL**
- **Sidekiq + sidekiq-scheduler** — background jobs and daily scheduling
- **HTTParty** — Empire Flippers API integration
- **hubspot-api-client** — HubSpot Deals API integration
- **RSpec + WebMock** — testing

## Setup

### 1. Install dependencies
```bash
bundle install
```

### 2. Configure database
Update `config/database.yml` with your PostgreSQL credentials then:
```bash
rails db:create db:migrate
```

### 3. Configure HubSpot credentials
```bash
EDITOR="code --wait" rails credentials:edit
```
Add:
```yaml
hubspot:
  access_token: your-pat-token-here
```

### 4. Start Sidekiq
```bash
bundle exec sidekiq
```

### 5. Run the sync job manually
```bash
rails console
SyncListingsJob.new.perform
```

## Architecture

```
EmpireFlippersService   — fetches For Sale listings from the API (handles pagination)
HubspotService          — creates and updates Deal objects in HubSpot
SyncListingsJob         — orchestrates the sync, prevents duplicates via hubspot_deal_id
config/sidekiq.yml      — schedules the job to run daily at midnight UTC
```

## Duplicate Prevention & Deal Updates

Each listing stores the HubSpot `deal_id` after creation. On subsequent runs:
- If a listing already has a `hubspot_deal_id` — the existing deal is **updated** with the latest price and summary
- If no `hubspot_deal_id` exists — a new deal is **created** in HubSpot

This ensures no duplicate deals are created and deal data stays in sync with the latest listing information.

## Running Tests

```bash
bundle exec rspec
```

**7 examples, 0 failures**

| Test | Coverage |
|---|---|
| EmpireFlippersService | Fetches listings, handles empty response |
| HubspotService | Creates deal with correct properties |
| SyncListingsJob | Creates new listing + deal, skips duplicates, updates existing listings |

## Daily Schedule

The sync runs automatically every day at midnight UTC via sidekiq-scheduler:

```yaml
:schedule:
  sync_listings:
    cron: "0 0 * * *"
    class: SyncListingsJob
    queue: default
```