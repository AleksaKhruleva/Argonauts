#!/usr/bin/env python3

from wsgiref.simple_server import make_server
from cgi import parse_qs, escape
import os
import sys
import mysql.connector
from mysql.connector.errors import Error
import json
from datetime import datetime
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import socket
import random
from datetime import datetime
import time

import asyncio
from aioapns import APNs, NotificationRequest, PushType


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
    response_dict['users'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    mydb.commit()
    mydb.close()


def dump_date(thing):
    if isinstance(thing, datetime):
        return thing.isoformat()
    return str(thing)


def send_notification(response_dict):
    token_hex = '67833776a59441dbe80af454c153b2bc84345babe2baa7960140001d08e104c2'

    async def run():
        apns_cert_client = APNs(
            client_cert='/etc/ssl/Certificates.pem',
            use_sandbox=True,
        )
        # apns_key_client = APNs(
        #     key='AuthKey_8J93N9S525.p8',
        #     key_id='8J93N9S525',
        #     team_id='8FRM8M93L5',
        #     topic='site.aleksa.forFun',  # Bundle ID
        #     use_sandbox=True,
        # )
        request = NotificationRequest(
            device_token=token_hex,
            message={
                "aps": {"alert": "Hello from forFun"
                    , "sound": "default"
                    , "badge": "1"
                }
            },
            # notification_id=str(uuid4()),  # optional
            # time_to_live=3,                # optional
            # push_type=PushType.ALERT,      # optional
        )
        await apns_cert_client.send_notification(request)
        # await apns_key_client.send_notification(request)

    loop = asyncio.get_event_loop()
    loop.run_until_complete(run())



    response_dict['wnotification'] = 'Sent'
    return response_dict







def connect_device(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]
        code = query_dict['code'][0]
        s = smtplib.SMTP('smtp.mail.ru', 587)
        s.starttls()
        s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
        msg = MIMEMultipart()

        message_template = 'Превед! :)\n\nНе отвечайте на это письмо!\n\nКод проверки: ' + code
        message = message_template  # .substitute(PERSON_NAME=name.title())

        msg['From'] = 'noreply@argonauts.online'
        msg['To'] = email
        msg['BCC'] = 'sent@argonauts.online'
        msg['Subject'] = 'confirmation code'

        msg.attach(MIMEText(message, 'plain'))
        s.send_message(msg)

        del msg

        response_dict['message'] = {'email': email, 'code': code}
    except:
        response_dict['message'] = {'server_error': 1}

    return response_dict

def is_email_exists(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]
        mydb.connect()
        mycursor = mydb.cursor()
        mycursor.execute("SELECT uid FROM email WHERE email = '%s'" % (email))
        res = mycursor.fetchall()
        if res == []:
            response_dict['user'] = {'no' : 'no'}
        else:
            uid = res[0][0]
            response_dict['user'] = {'uid' : uid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['user'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def add_user(mydb, query_dict, response_dict):
    try:
        nick = query_dict['nick'][0]
        email = query_dict['email'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("INSERT INTO user (nick) VALUE ('%s')" % nick)
        mycursor.execute("SELECT LAST_INSERT_ID()")

        uid = mycursor.fetchone()[0]
        mycursor.execute("INSERT INTO email (uid, email) VALUES (%d, '%s')" % (uid, email))

        mydb.commit()
        response_dict['new_user'] = {'email': email, 'nick': nick, 'uid': uid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['new_user'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_tid_tnick(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT nick, tid FROM transport WHERE uid = (SELECT uid FROM email WHERE email = '%s') ORDER BY nick" % (email))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['tid_nick'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['tid_nick'] = [{'server_error' : 1, 'err_code' : err_code}]
    finally:
        mydb.close()

    return response_dict

def get_transport_info(mydb, query_dict, response_dict):
    try:
        tid = int(query_dict['tid'][0])

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM transport WHERE tid = %d" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['transport_info'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['transport_info'] = [{'server_error' : 1, 'err_code' : err_code}]
    finally:
        mydb.close()

    return response_dict

def update_transp_info(mydb, query_dict, response_dict):
    try:
        tid = int(query_dict['tid'][0])
        resp = {'tid': tid}

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("UPDATE transport SET nick = '%s' WHERE tid = %d" % (query_dict['nick'][0], tid))
        resp['nick'] = query_dict['nick'][0]

        if 'producted' in query_dict:
            mycursor.execute("UPDATE transport SET producted = %s WHERE tid = %d" % (query_dict['producted'][0], tid))
            resp['producted'] = query_dict['producted'][0]
        if 'diag_date' in query_dict:
            mycursor.execute("UPDATE transport SET diag_date = '%s' WHERE tid = %d" % (query_dict['diag_date'][0], tid))
            resp['diag_date'] = query_dict['diag_date'][0]
        if 'osago_date' in query_dict:
            mycursor.execute("UPDATE transport SET osago_date = '%s' WHERE tid = %d" % (query_dict['osago_date'][0], tid))
            resp['osago_date'] = query_dict['osago_date'][0]
        mydb.commit()
        response_dict['update_transp_info'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['update_transp_info'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def add_transp(mydb, query_dict, response_dict):
    email = query_dict['email'][0]
    nick = query_dict['nick'][0]

    mydb.connect()
    mycursor = mydb.cursor()

    try:
        mycursor.execute("INSERT INTO transport (uid, nick) SELECT uid, '%s' from email WHERE email = '%s'" % (nick, email))
        mycursor.execute("SELECT LAST_INSERT_ID()")

        tid = mycursor.fetchone()[0]

        resp = {'tid': tid, 'nick' : nick, 'email' : email}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_transp'] = {'server_error': 1, 'err_code': err_code}
        mydb.close()
        return response_dict

    try:
        now = datetime.now()
        date_string = now.strftime('%Y-%m-%d %H:%M:%S')

        if 'producted' in query_dict:
            mycursor.execute("UPDATE transport SET producted = %s WHERE tid = %d" % (query_dict['producted'][0], tid))
            resp['producted'] = query_dict['producted'][0]
        if 'mileage' in query_dict:
            mycursor.execute("UPDATE transport SET mileage = %s WHERE tid = %d" % (query_dict['mileage'][0], tid))
            try:
                mycursor.execute("INSERT INTO mileage (tid, date, mileage) VALUES (%s, '%s', %s)" % (tid, date_string, query_dict['mileage'][0]))
            except mysql.connector.Error as error:
                err_code = int(str(error).split()[0])
                resp['mileage'] = {'server_error' : 1, 'err_code' : err_code}
            resp['mileage'] = {'mileage' : query_dict['mileage'][0]}
        if 'eng_hour' in query_dict:
            mycursor.execute("UPDATE transport SET eng_hour = %s WHERE tid = %d" % (query_dict['eng_hour'][0], tid))
            try:
                mycursor.execute("INSERT INTO eng_hour (tid, date, eng_hour) VALUES (%s, '%s', %s)" % (tid, date_string, query_dict['eng_hour'][0]))
            except mysql.connector.Error as error:
                err_code = int(str(error).split()[0])
                resp['eng_hour'] = {'server_error' : 1, 'err_code' : err_code}
            resp['eng_hour'] = query_dict['eng_hour'][0]
        if 'diag_date' in query_dict:
            mycursor.execute("UPDATE transport SET diag_date = '%s' WHERE tid = %d" % (query_dict['diag_date'][0], tid))
            diag_date = query_dict['diag_date'][0]
            resp['diag_date'] = diag_date
        if 'osago_date' in query_dict:
            mycursor.execute("UPDATE transport SET osago_date = '%s' WHERE tid = %d" % (query_dict['osago_date'][0], tid))
            osago_date = query_dict['osago_date'][0]
            resp['osago_date'] = osago_date
        mydb.commit()
        response_dict['add_transp'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_transp'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_user_info(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]

        mydb.connect()
        mycursor = mydb.cursor()
        mycursor.execute("SELECT nick from user WHERE uid = (SELECT uid FROM email WHERE email = '%s')" % (email))
        nick = mycursor.fetchall()

        response_dict['user_info'] = {'nick' : nick[0][0]}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['user_info'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_mileage(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM mileage WHERE tid = %s ORDER BY date DESC" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_mileage'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_mileage'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_mileage(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]
        date = query_dict['date'][0]
        mileage = query_dict['mileage'][0]

        mydb.connect()
        mycursor = mydb.cursor()
        mycursor.execute("INSERT INTO mileage (tid, date, mileage) SELECT %s, '%s', %s FROM DUAL WHERE NOT EXISTS (SELECT * FROM mileage WHERE tid = %s AND ('%s' > date AND %s < mileage OR '%s' < date AND %s > mileage OR '%s' = date AND %s = mileage))" % (tid, date, mileage, tid, date, mileage, date, mileage, date, mileage))
        affected_rows = mycursor.rowcount

        if affected_rows == 0:
            response_dict['add_mileage'] = {'row' : affected_rows}
        else:
            mycursor.execute("SELECT LAST_INSERT_ID()")
            mid = mycursor.fetchone()[0]
            mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))
            mydb.commit()
            response_dict['add_mileage'] = {'row': affected_rows, 'mid': mid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_mileage'] = {'server_error' : 1, 'err_code' : err_code, 'row' : 0}
    finally:
        mydb.close()

    return response_dict

def delete_mileage(mydb, query_dict, response_dict):
    try:
        mid = query_dict['mid'][0]
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM mileage WHERE mid = %s" % (mid))
        mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))

        mydb.commit()
        response_dict['delete_mileage'] = {'deleted_mid': mid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_mileage'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_eng_hour(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM eng_hour WHERE tid = %s ORDER BY date DESC" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_eng_hour'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_eng_hour'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_eng_hour(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]
        date = query_dict['date'][0]
        eng_hour = query_dict['eng_hour'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("INSERT INTO eng_hour (tid, date, eng_hour) SELECT %s, '%s', %s FROM DUAL WHERE NOT EXISTS (SELECT * FROM eng_hour WHERE tid = %s AND ('%s' > date AND %s < eng_hour OR '%s' < date AND %s > eng_hour OR '%s' = date AND %s = eng_hour))" % (tid, date, eng_hour, tid, date, eng_hour, date, eng_hour, date, eng_hour))
        affected_rows = mycursor.rowcount

        if affected_rows == 0:
            response_dict['add_eng_hour'] = {'row' : affected_rows}
        else:
            mycursor.execute("SELECT LAST_INSERT_ID()")
            ehid = mycursor.fetchone()[0]
            mycursor.execute("UPDATE transport SET eng_hour = (SELECT MAX(eng_hour) FROM eng_hour WHERE tid = %s) WHERE tid = %s" % (tid, tid))
            mydb.commit()
            response_dict['add_eng_hour'] = {'row': affected_rows, 'ehid': ehid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_eng_hour'] = {'server_error' : 1, 'err_code' : err_code, 'row' : 0}
    finally:
        mydb.close()

    return response_dict

def delete_eng_hour(mydb, query_dict, response_dict):
    try:
        ehid = query_dict['ehid'][0]
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM eng_hour WHERE ehid = %s" % (ehid))
        mycursor.execute("UPDATE transport SET eng_hour = (SELECT MAX(eng_hour) FROM eng_hour WHERE tid = %s) WHERE tid = %s" % (tid, tid))

        mydb.commit()
        response_dict['delete_eng_hour'] = {'deleted_ehid': ehid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_eng_hour'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_fuel(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT f.*, m.mileage FROM fuel AS f LEFT JOIN mileage as m ON f.date = m.date WHERE f.tid = %s ORDER BY date DESC" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_fuel'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_fuel'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_fuel(mydb, query_dict, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    resp = dict()
    global fid
    
    try:
        tid = query_dict['tid'][0]
        date = query_dict['date'][0]
        mileage = query_dict['mileage'][0]
        fuel = query_dict['fuel'][0]

        mycursor.execute("INSERT INTO mileage (tid, date, mileage) SELECT %s, '%s', %s FROM DUAL WHERE NOT EXISTS (SELECT * FROM mileage WHERE tid = %s AND ('%s' > date AND %s < mileage OR '%s' < date AND %s > mileage OR '%s' = date AND %s = mileage))" % (tid, date, mileage, tid, date, mileage, date, mileage, date, mileage))
        affected_rows = mycursor.rowcount

        if affected_rows == 0:
            response_dict['add_fuel'] = {'row': affected_rows, 'mileage_inserted' : 0}
        else:
            mycursor.execute("INSERT INTO fuel (tid, date, fuel) VALUES (%s, '%s', %s)" % (tid, date, fuel))
            affected_rows = mycursor.rowcount

            if affected_rows == 0:
                response_dict['add_fuel'] = {'row' : affected_rows}
            else:
                mycursor.execute("SELECT LAST_INSERT_ID()")
                fid = mycursor.fetchone()[0]
                mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))

                resp['fid'] = fid
                resp['date'] = date
                resp['mileage'] = int(mileage)
                resp['fuel'] = int(fuel)
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_fuel'] = {'server_error': 1, 'err_code': err_code}
        mydb.close()
        return response_dict

    try:
        if 'fill_brand' in query_dict:
            mycursor.execute("UPDATE fuel SET fill_brand = '%s' WHERE fid = %s" % (query_dict['fill_brand'][0], fid))
            resp['fill_brand'] = query_dict['fill_brand'][0]
        if 'fuel_brand' in query_dict:
            mycursor.execute("UPDATE fuel SET fuel_brand = '%s' WHERE fid = %s" % (query_dict['fuel_brand'][0], fid))
            resp['fuel_brand'] = query_dict['fuel_brand'][0]
        if 'fuel_cost' in query_dict:
            mycursor.execute("UPDATE fuel SET fuel_cost = %s WHERE fid = %s" % (query_dict['fuel_cost'][0], fid))
            resp['fuel_cost'] = float(query_dict['fuel_cost'][0])
        mydb.commit()
        response_dict['add_fuel'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_fuel'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def delete_fuel(mydb, query_dict, response_dict):
    try:
        fid = query_dict['fid'][0]
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM mileage WHERE tid = %s AND date = (SELECT date FROM fuel WHERE fid = %s)" % (tid, fid))
        mycursor.execute("DELETE FROM fuel WHERE fid = %s" % (fid))
        mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))

        mydb.commit()
        response_dict['delete_fuel'] = {'deleted_fid': fid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_fuel'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_service(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT s.*, m.mileage FROM service AS s LEFT JOIN mileage as m ON s.date = m.date WHERE s.tid = %s ORDER BY date DESC" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_service'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_service'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_service(mydb, query_dict, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    resp = dict()

    try:
        tid = query_dict['tid'][0]
        date = query_dict['date'][0]
        ser_type = query_dict['ser_type'][0]
        mileage = query_dict['mileage'][0]

        mycursor.execute("INSERT INTO mileage (tid, date, mileage) SELECT %s, '%s', %s FROM DUAL WHERE NOT EXISTS (SELECT * FROM mileage WHERE tid = %s AND ('%s' > date AND %s < mileage OR '%s' < date AND %s > mileage OR '%s' = date AND %s = mileage))" % (tid, date, mileage, tid, date, mileage, date, mileage, date, mileage))
        affected_rows = mycursor.rowcount

        if affected_rows == 0:
            response_dict['add_service'] = {'row': affected_rows, 'mileage_inserted': 0}
        else:
            mycursor.execute("INSERT INTO service (tid, date, ser_type) VALUES (%s, '%s', '%s')" % (tid, date, ser_type))
            affected_rows = mycursor.rowcount

            if affected_rows == 0:
                response_dict['add_service'] = {'row': affected_rows, 'service_inserted': 0}
            else:
                mycursor.execute("SELECT LAST_INSERT_ID()")
                sid = mycursor.fetchone()[0]
                mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))

                resp['sid'] = sid
                resp['date'] = date
                resp['ser_type'] = ser_type
                resp['mileage'] = int(mileage)
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_service'] = {'server_error': 1, 'err_code': err_code}
        mydb.close()
        return response_dict
    try:
        if 'mat_cost' in query_dict:
            mycursor.execute("UPDATE service SET mat_cost = %s WHERE sid = %s" % (query_dict['mat_cost'][0], sid))
            resp['mat_cost'] = query_dict['mat_cost'][0]
        if 'wrk_cost' in query_dict:
            mycursor.execute("UPDATE service SET wrk_cost = %s WHERE sid = %s" % (query_dict['wrk_cost'][0], sid))
            resp['wrk_cost'] = query_dict['wrk_cost'][0]
        mydb.commit()
        response_dict['add_service'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_service'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def delete_service(mydb, query_dict, response_dict):
    try:
        sid = query_dict['sid'][0]
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM mileage WHERE tid = %s AND date = (SELECT date FROM service WHERE sid = %s)" % (tid, sid))
        mycursor.execute("DELETE FROM service WHERE sid = %s" % (sid))
        mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))

        mydb.commit()
        response_dict['delete_service'] = {'deleted_sid': sid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_service'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_material(mydb, query_dict, response_dict):
    try:
        sid = query_dict['sid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM material WHERE sid = %s" % (sid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_material'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_material'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_material(mydb, query_dict, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    resp = dict()
    try:
        sid = query_dict['sid'][0]
        mat_info = query_dict['mat_info'][0]
        wrk_type = query_dict['wrk_type'][0]

        resp['mat_info'] = mat_info
        resp['wrk_type'] = wrk_type
        
        mycursor.execute("INSERT INTO material (sid, mat_info, wrk_type) VALUES (%s, '%s', '%s')" % (sid, mat_info, wrk_type))
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_material'] = {'server_error': 1, 'err_code': err_code}
        mydb.close()
        return response_dict

    try:
        mycursor.execute("SELECT LAST_INSERT_ID()")
        maid = mycursor.fetchone()[0]
        resp['maid'] = maid
        if 'mat_cost' in query_dict:
            mycursor.execute("UPDATE material SET mat_cost = %s WHERE maid = %s" % (query_dict['mat_cost'][0], maid))
            resp['mat_cost'] = float(query_dict['mat_cost'][0])
        if 'wrk_cost' in query_dict:
            mycursor.execute("UPDATE material SET wrk_cost = %s WHERE maid = %s" % (query_dict['wrk_cost'][0], maid))
            resp['wrk_cost'] = float(query_dict['wrk_cost'][0])
        mydb.commit()
        response_dict['add_material'] = resp
    except mysql.connector.Error as error:
        print(error)
        err_code = int(str(error).split()[0])
        response_dict['add_material'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def delete_material(mydb, query_dict, response_dict):
    try:
        maid = query_dict['maid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM material WHERE maid = %s" % (maid))

        mydb.commit()
        response_dict['delete_material'] = {'deleted_maid': maid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_material'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict






















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
        , 'cwd': os.getcwd()
                     }

    get_db_timestamp(argodb, response_dict)
    list_db_tables(argodb, response_dict)

    request_mission = query_dict.get('mission', [''])[0]

    if request_mission == 'show_table_ttypes':
        show_table_ttypes(argodb, response_dict)
    elif request_mission == 'show_table_users':
        show_table_users(argodb, response_dict)
    elif request_mission == 'send_notification':
        send_notification(response_dict)
    elif request_mission == 'connect_device':
        connect_device(argodb, query_dict, response_dict)
    elif request_mission == 'is_email_exists':
        is_email_exists(argodb, query_dict, response_dict)
    elif request_mission == 'add_user':
        add_user(argodb, query_dict, response_dict)
    elif request_mission == 'add_transp':
        add_transp(argodb, query_dict, response_dict)
    elif request_mission == 'get_tid_tnick':
        get_tid_tnick(argodb, query_dict, response_dict)
    elif request_mission == 'get_transport_info':
        get_transport_info(argodb, query_dict, response_dict)
    elif request_mission == 'update_transp_info':
        update_transp_info(argodb, query_dict, response_dict)
    elif request_mission == 'get_user_info':
        get_user_info(argodb, query_dict, response_dict)
    elif request_mission == 'add_mileage':
        add_mileage(argodb, query_dict, response_dict)
    elif request_mission == 'get_mileage':
        get_mileage(argodb, query_dict, response_dict)
    elif request_mission == 'delete_mileage':
        delete_mileage(argodb, query_dict, response_dict)
    elif request_mission == 'get_eng_hour':
        get_eng_hour(argodb, query_dict, response_dict)
    elif request_mission == 'add_eng_hour':
        add_eng_hour(argodb, query_dict, response_dict)
    elif request_mission == 'delete_eng_hour':
        delete_eng_hour(argodb, query_dict, response_dict)
    elif request_mission == 'get_fuel':
        get_fuel(argodb, query_dict, response_dict)
    elif request_mission == 'add_fuel':
        add_fuel(argodb, query_dict, response_dict)
    elif request_mission == 'delete_fuel':
        delete_fuel(argodb, query_dict, response_dict)
    elif request_mission == 'get_service':
        get_service(argodb, query_dict, response_dict)
    elif request_mission == 'add_service':
        add_service(argodb, query_dict, response_dict)
    elif request_mission == 'delete_service':
        delete_service(argodb, query_dict, response_dict)
    elif request_mission == 'get_material':
        get_material(argodb, query_dict, response_dict)
    elif request_mission == 'add_material':
        add_material(argodb, query_dict, response_dict)
    elif request_mission == 'delete_material':
        delete_material(argodb, query_dict, response_dict)
    
    response_status = '200 OK'
    response_json = bytes(json.dumps(response_dict, default=dump_date, indent=2, ensure_ascii=False, sort_keys=True), encoding='utf-8')
    response_headers = [('Content-type', 'text/plain; charset=utf-8'), ('Content-Length', str(len(response_json)))]
    start_response(response_status, response_headers)

    # time.sleep(2)
    return [response_json]
