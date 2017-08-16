#! /bin/bash
source ~/apps/pgadmin4/venv/bin/activate
python ~/apps/pgadmin4/venv/local/lib/python2.7/site-packages/pgadmin4/pgAdmin4.py & 
sleep 5; sensible-browser http://127.0.0.1:5050