"""
wsgi.py — WSGI entrypoint for StockGrid.

The application package lives in app/, so `app` is a package and can no longer
also be a module. This file is the single place that builds the application
object for a server to serve.

    python wsgi.py            development server
    gunicorn wsgi:app         production
"""
from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run(debug=True, port=5000)
