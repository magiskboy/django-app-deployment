#!/bin/sh

cd demo

python manage.py collectstatic

gunicorn --bind 127.0.0.1:8000 --workers 2 demo.wsgi:application
