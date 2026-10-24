# StockGrid — Inventory & Sales Management System

A web-based inventory and sales management system for small businesses, built with Python, Flask and MySQL. It tracks stock across locations, handles sales and purchase orders, and uses forecasting to warn when products are about to run out.

Built as a Final Year Project at City University Malaysia.

## Screenshots

| Dashboard | AI demand forecast |
|---|---|
| ![Dashboard](docs/screenshots/01-dashboard.png) | ![AI demand forecast](docs/screenshots/02-ai-demand-forecast.png) |

| Alerts & notifications | Sales orders |
|---|---|
| ![Alerts](docs/screenshots/03-alerts.png) | ![Sales orders](docs/screenshots/04-sales-orders.png) |

| Purchase orders | Reports |
|---|---|
| ![Purchase orders](docs/screenshots/05-purchase-orders.png) | ![Reports](docs/screenshots/06-reports.png) |

## Features

- **Dashboard** with inventory value, top-selling and top-stocked items, and pending actions
- **Products and stock health** with colour-coded levels (healthy, restock soon, critical)
- **Stock in/out movements, adjustments and transfers** between locations, with a full history log
- **Sales** — orders, invoices, returns and credit notes
- **Purchases** — purchase orders, goods receiving, bills and vendor payments
- **AI demand forecast** that estimates each product's stockout date and suggests a reorder quantity
- **AI intelligence** — demand models, anomaly detection, ABC classification and stock health scoring
- **Alerts** for critical stock, overdue purchase orders and overdue invoices
- **26 built-in reports** for sales, inventory and purchases
- **Warehousing and tracking** — batches and expiry, serial numbers, composite items, price lists
- **Fulfilment** — picklists, packages and shipments
- **Access control** — roles and permissions, audit log, Google sign-in
- **Documents and integration** — PDF invoices, CSV import, low-stock email alerts, webhooks

## How the forecasting works

- The **AI Forecast** page estimates daily consumption from recorded stock-out movements using a recency-weighted moving average with a trend term. It projects the stockout date and recommends a reorder quantity when that date falls within the supplier's lead time.
- The **AI Intelligence** engine in `app/ai/` adds machine-learning models: XGBoost for demand, Isolation Forest (scikit-learn) for anomaly detection, and STL decomposition (statsmodels) for seasonality.
- Forecasts need history. Record some stock-out movements before expecting useful predictions.

## Tech stack

Python · Flask · MySQL · pandas · NumPy · scikit-learn · XGBoost · statsmodels · Gunicorn · Docker · HTML/CSS/JavaScript

## Getting started

Requires Python 3.10+ and MySQL (or MariaDB).

```bash
# 1. Create a virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure environment
cp .env.example .env            # then set STOCKGRID_DB_PASSWORD and STOCKGRID_SECRET_KEY

# 4. Create the database (first time only)
python scripts/setup_db.py

# 5. Create an admin account
python scripts/make_admin.py <username> <password>

# 6. Run
python wsgi.py                  # development, http://localhost:5000
gunicorn wsgi:app               # production
```

Credentials are read from environment variables. Nothing is hardcoded. With `FLASK_ENV=production` the app refuses to start unless `STOCKGRID_SECRET_KEY` and `STOCKGRID_DB_PASSWORD` are set. Later schema changes are applied automatically at startup.

A `Dockerfile` is included for container deployment.

## Tests

```bash
pip install pytest
pytest
```

## Project structure

```
stockgrid/
├── wsgi.py            # entry point
├── app/
│   ├── routes/        # HTTP handlers: parse request, call a service, respond
│   ├── services/      # business rules and SQL (no Flask imports)
│   ├── ai/            # forecasting and analytics engine
│   ├── migrations/    # schema migrations, run at startup
│   ├── templates/     # Jinja pages
│   └── static/        # CSS, JS, images
├── db/                # base schema files
├── scripts/           # setup_db.py, make_admin.py
└── tests/             # pytest suite
```

Layering rule: a route may call a service; a service never imports Flask.

More detail is in [`ARCHITECTURE.md`](ARCHITECTURE.md) and [`DATABASE.md`](DATABASE.md).

## Security notes

- Never commit `.env`. It is listed in `.gitignore`.
- Database dumps are ignored too, because they contain real records.
- `make_admin.py` creates accounts with a password you choose. There are no default credentials.

## License

[MIT](LICENSE)
