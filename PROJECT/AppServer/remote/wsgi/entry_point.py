#!/usr/bin/env python3

from wsgiref.simple_server import make_server
from cgi import parse_qs, escape
import os
import sys
import mysql.connector
import json
from datetime import datetime
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import socket


# argo_user = os.getenv('ARGO_USER')
# argo_pass = os.getenv('ARGO_PASS')
# argo_base = os.getenv('ARGO_BASE')

# argodb = mysql.connector.connect(
#   host="localhost",
#   user=argo_user,
#   password=argo_pass,
#   database=argo_base
# )
# argodb = mysql.connector.connect(
#   host="localhost",
#   user='argouser',
#   password='argopassword',
#   database='argodb'
# )


def get_db_timestamp(mydb, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    mycursor.execute('SELECT DATE_FORMAT(current_timestamp(6), \'%Y-%m-%d-%H.%i.%s.%f\') AS ts_mysql')
    myresult = mycursor.fetchall()
    response_dict['db.timestamp'] = myresult[0][0]
    mydb.commit()
    mydb.close()


def list_db_tables(mydb, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    mycursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = %s", ('argodb',))
    response_dict['db.tables'] = [row[0] for row in mycursor.fetchall()]
    mydb.commit()
    mydb.close()


def show_table_ttypes(mydb, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    mycursor.execute('SELECT * FROM ttypes ORDER BY rid')
    columns = [desc[0] for desc in mycursor.description]
    response_dict['ttypes'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    mydb.commit()
    mydb.close()


def show_table_users(mydb, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    mycursor.execute('SELECT * FROM users ORDER BY rid')
    columns = [desc[0] for desc in mycursor.description]
    response_dict['ttypes'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    mydb.commit()
    mydb.close()


def dump_date(thing):
    if isinstance(thing, datetime):
        return thing.isoformat()
    return str(thing)


def application(environ, start_response):
    argo_user = environ['ARGO_USER']
    argo_pass = environ['ARGO_PASS']
    argo_base = environ['ARGO_BASE']
    argodb = mysql.connector.connect(
        host="localhost",
        user=argo_user,
        password=argo_pass,
        database=argo_base
    )
    # argodb = mysql.connector.connect(
    #   host="localhost",
    #   user='argouser',
    #   password='argopassword',
    #   database='argodb'
    # )
    query_dict = parse_qs(environ['QUERY_STRING'])
    response_dict = {'proto_ver': '1.0.0'
        , 'sys.version': sys.version
        , 'query_dict': str(query_dict)
        , 'hostname': socket.gethostname()
                     }

    get_db_timestamp(argodb, response_dict)
    list_db_tables(argodb, response_dict)

    request_mission = query_dict.get('mission', [''])[0]

    if request_mission == 'show_table_ttypes':
        show_table_ttypes(argodb, response_dict)
    if request_mission == 'show_table_users':
        show_table_users(argodb, response_dict)

    response_status = '200 OK'
    response_json = bytes(json.dumps(response_dict, default=dump_date, indent=2, ensure_ascii=False, sort_keys=True), encoding='utf-8')
    response_headers = [('Content-type', 'text/plain; charset=utf-8'), ('Content-Length', str(len(response_json)))]
    start_response(response_status, response_headers)

    return [response_json]
