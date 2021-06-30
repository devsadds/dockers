#!/usr/bin/env python3.9
import pika
import os
import time
import json
import argparse
import sys
import re
import subprocess
import psycopg2
import mysql.connector
import jsontree
import datetime
import logging
import sentry_sdk
from flask import Flask
from flask import Flask, request, current_app, g, jsonify, request_finished, make_response, abort
from sentry_sdk.integrations.logging import LoggingIntegration
import tornado
import tornado.web
import tornado.options
from ipaddress import IPv4Address
import ipaddr, ipaddress
import tempfile
import uuid
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import requests
import memorize
from json import dumps
if os.environ.get('THREADS'):
    threads = int(os.environ['THREADS'])
else:
    threads = 0

app = Flask(__name__)
#------------------
#-----CONF PARAMS--
treads_count_started = 3
now = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime())
formatted_command = "empty"
log_file_name = "empty"
version = "1.0.0"
executor = os.uname()[1]

#-----------------
#-----VARS ENV----
HTTP_HOST_INCOMING = os.getenv('HTTP_HOST_INCOMING', 'whlisten.linux2be.com')
HTTP_HOST_OUTGOING = os.getenv('HTTP_HOST_OUTGOING', 'outgoing-demo.linux2be.com')
HTTP_URL_OUTGOING = os.getenv('HTTP_URL_OUTGOING', 'https://rx.example.com/api/sms/receive')
MYSQL_DB_HOST      = os.getenv('MYSQL_DB_HOST', '127.0.0.1')
MYSQL_DB_PORT      = os.getenv('MYSQL_DB_PORT', '3306')
MYSQL_DB_USER      = os.getenv('MYSQL_DB_USER', 'whlisten_db')
MYSQL_DB_PASSWORD  = os.getenv('MYSQL_DB_PASSWORD', 'sdsdsdsds')
MYSQL_DB_NAME      = os.getenv('MYSQL_DB_NAME', 'whlisten_db')
MYSQL_CACHE_TIMEOUT      = int(os.getenv('MYSQL_CACHE_TIMEOUT', 300))
POSTGRES_DB_PORT   = os.getenv('POSTGRES_DB_PORT', '5432')
POSTGRES_DB_NAME   = os.getenv('POSTGRES_DB_NAME', 'ansible')
POSTGRES_DB_USER   = os.getenv('POSTGRES_DB_USER', 'postgres')
POSTGRES_DB_PASSWORD     = os.getenv('POSTGRES_DB_PASSWORD', 'hfdf23dfdfj3llL')
POSTGRES_TABLE_NAME_JOBS = os.getenv('POSTGRES_TABLE_NAME_JOBS', 'tbl_ansible_jobs')
POSTGRES_TABLE_NAME_LOGS = os.getenv('POSTGRES_TABLE_NAME_LOGS', 'tbl_ansible_logs')
SCRIPTS_STORE_DIR        = os.getenv('SCRIPTS_STORE_DIR', '/tmp')
SENTRY_URL               = os.getenv('SENTRY_URL', 'https://abc5140d3a9242b38dbbc6b0136bcf44:f28aa7bc642c4c34a4d253d12e2ldadf@sentry.example.com/2')
SENTRY_SERVER_NAME       = os.getenv('SENTRY_SERVER_NAME', executor)
RMPQ_HOST      = os.getenv('RMPQ_HOST', 'rabbitmq')
RMPQ_PORT      = os.getenv('RMPQ_PORT', '5672')
RMPQ_USER      = os.getenv('RMPQ_USER', 'user')
RMPQ_PASSWORD  = os.getenv('RMPQ_PASSWORD', 'CfitCyjdf18higuigTMOuizDVAFjB88')
RMPQ_SSL_OPT   = os.getenv('RMPQ_SSL_OPT', '') 
RMPQ_QUEUE_RX  = os.getenv('RMPQ_QUEUE_RX', 'sms-http-rx') 
RMPQ_QUEUE_ACL = os.getenv('RMPQ_QUEUE_ACL', 'sms-http-rx-hosts-allow') 
ENV_DEBUG      = os.getenv('ENV_DEBUG', 'True')


logging.getLogger().addHandler(logging.StreamHandler())

def get_logger():
    logger = logging.getLogger("threading_example")
    logger.setLevel(logging.DEBUG)

    fh = logging.FileHandler("threading.log")
    fmt = '%(asctime)s - %(threadName)s - %(levelname)s - %(message)s'
    formatter = logging.Formatter(fmt)
    fh.setFormatter(formatter)

    logger.addHandler(fh)
    return logger


def send_post(url,r_content_type,headers,payload):
    if r_content_type  == "application/json":
        r = requests.post(url,data=json.dumps(payload),headers=headers)
    else:
        print("send_post with no json " + str(r_content_type))
        print('headers = ' + str(headers))
        r = requests.post(url,data=payload,headers=headers)
    if r.status_code == 200:
        print('Success! ' + str(r.reason))
        r_data = json.dumps({"r_code":r.status_code,"r_reason":str(r.reason),"r_content":str(r.content),"r_text":str(r.text),"r_headers":dict(r.headers) })
    else:
        print('Error. ' + str(r.reason))
        r_data = json.dumps({"r_code":r.status_code,"r_reason":str(r.reason),"r_content":str(r.content),"r_text":str(r.text),"r_headers":dict(r.headers) })
    
    return r_data

def send_get(url,r_content_type,r_data):
    get_args = r_data['args']
    headers = r_data['headers']
    print("Exec query headers")
    print(headers)
    print("Exec query get_args")
    print(get_args)
    r = requests.get(url,params=get_args,headers=headers)
    print("r.status_code = " +  str(r.status_code))
    if r.status_code == 200:
        print('Success! ' + str(r.reason))
        r_data = json.dumps({"r_code":r.status_code,"r_reason":str(r.reason),"r_content":str(r.content),"r_text":str(r.text),"r_headers":dict(r.headers) })
    else:
        print('Error. ' + str(r.reason))
        r_data = json.dumps({"r_code":r.status_code,"r_reason":str(r.reason),"r_content":str(r.content),"r_text":str(r.text),"r_headers":dict(r.headers) })
    return r_data

@memorize.memorize(timeout=MYSQL_CACHE_TIMEOUT)
def getfromDb_whlisten_db():
    mysql_data = []
    try:
        con = mysql.connector.connect(
            host=MYSQL_DB_HOST,
            port=int(MYSQL_DB_PORT),
            user=MYSQL_DB_USER,
            password=MYSQL_DB_PASSWORD,
            ssl_disabled=True,
            db=MYSQL_DB_NAME)
        cur = con.cursor()
        cur.execute("select ip from sms_allowed_ips where active = 1 and deleted_at IS NULL")
        for row in cur.fetchall():
            mysql_data.append(row)
    except:
        logging.exception("Error. Select from mysql db " + str(MYSQL_DB_NAME) + "failed")
    try:
        con.close()
    except:
        pass
    return mysql_data


def save_request(uuid, request):

    req_data = {}

    req_data['uuid'] = uuid
    req_data['endpoint'] = request.endpoint
    req_data['method'] = request.method
    req_data['Content-Type'] = request.content_type
    req_data['headers'] = dict(request.headers)
    req_data['headers']['X-Auth'] = dict(request.headers)['Remote-Addr']
    req_data['headers']['Host'] = HTTP_HOST_OUTGOING
    req_data['headers']['http_host_origin'] = req_data['headers']['Host'].split(":", 1)[0]
    req_data['headers']['http_host_target'] = HTTP_HOST_OUTGOING
    req_data['remote_addr'] = req_data['headers']['Remote-Addr']
    req_data['headers'].pop('Cookie', None)
    if req_data['method'] == "POST" and req_data['Content-Type'] == "application/json":
        req_data['data'] = request.get_json(force = True)
        req_data['args'] = request.args
        print(f"{request.args=}")
    elif req_data['method'] == "GET":
        req_data['args'] = request.args
        print(f"{request.args=}")
    elif req_data['method'] == "POST" and req_data['Content-Type'] != "application/json":
        req_data['args'] = request.args
        req_data['data_plain'] = request.form     
    return req_data

def save_response(uuid, resp):
    resp_data = {}
    resp_data['uuid'] = uuid
    resp_data['status_code'] = resp.status_code
    resp_data['status'] = resp.status
    resp_data['headers'] = dict(resp.headers)
    resp_data['data'] = resp.response

    return resp_data


@app.before_request
def before_request():
    g.uuid = str(uuid.uuid4())


@app.before_request
def block_method():
    #db_data = getfromDb_whlisten_db()
    #ip_addr_v4_whitelist = []
    #for row in db_data:
    #    ip_addr_v4_white = IPv4Address(int(row[0]))
    #    ip_addr_v4_whitelist.append(ip_addr_v4_white)
    #ip = request.environ.get('REMOTE_ADDR')
    ip = request.headers['Remote-Addr']
    m_http_host = request.headers['Host'].split(":", 1)
    m_http_host = m_http_host[0]
    print("---Debug request.headers---")
    print(request.headers)
    print("---Debug equest.headers---")
    print("------request.data---")
    print(request.data)
    print("------request.data---")

    #print(str(ip_addr_v4_whitelist))
    #print("---ip_addr_v4_whitelist---")
    ###
    rule = request.url_rule
    print('rule')
    print(rule)
    ###if '/api/sms/healthcheck/front' in rule.rule:
        ###print('Healthcheck only')
    ###else:
        ###if ipaddress.ip_address(ip) in ip_addr_v4_whitelist:
            ###print("Accepted connection from " + ip)
        ###else:
            ###print("Forbidden connection from " + ip)
            ###abort(403, 'Forbidden')
        ###if m_http_host in HTTP_HOST_INCOMING:
            ###print("Request for host " + m_http_host + " accepted" + " from ip " + ip )
        ###else:
            ###print("Request for host " + m_http_host + " not allowed" + " from ip " + ip )
            ###print("Allowed hosts is = " + HTTP_HOST_INCOMING )
            ###abort(404)


@app.after_request
def after_request(resp):
    resp.headers.add('Access-Control-Allow-Origin', '*')
    resp.headers.add('Access-Control-Allow-Headers', 'Content-Type, X-Token, X-Auth')
    resp.headers.add('Access-Control-Allow-Methods', 'GET, POST')
    resp_data = save_response(g.uuid, resp)

    return resp

@app.route('/api/sms/healthcheck/front', methods=['GET', 'POST'])
def web_healthcheck():
    data = {'message': 'online', 'status': 'healhy'}
    return make_response(jsonify(data), 200)

@app.route('/', methods=['GET', 'POST'])

def main_route():
    print("-------------------------------" + " R_START " + "-------------------------------")

    req_data = save_request(g.uuid, request)
    resp = json.dumps(req_data, indent=4)
    m_http_host = req_data['headers']['Host'].split(":", 1)[0]
    r_data = json.loads(resp)
    print("HTTP_HOST_INCOMING = " + HTTP_HOST_INCOMING)
    print("HTTP_HOST_OUTGOING = " + HTTP_HOST_OUTGOING)
    print("HTTP_Content_Type = " + str(req_data['Content-Type']))

    ###if req_data['method'] == "POST" and req_data['Content-Type'] == "application/json":
        ###print("resend " + " Content-Type " + str(req_data['Content-Type']) + " to host " + HTTP_HOST_OUTGOING )
        ###r_send = send_post(HTTP_URL_OUTGOING,req_data['Content-Type'],r_data['headers'],r_data['data'])
    ###elif req_data['method'] == "POST" and req_data['Content-Type'] != "application/json":
        ###print("resend " + " Content-Type " + str(req_data['Content-Type']) + " to host " + HTTP_HOST_OUTGOING )
        ###r_send = send_post(HTTP_URL_OUTGOING,req_data['Content-Type'],r_data['headers'],r_data['data_plain'])
    ###elif req_data['method'] == "GET":
        ###print("resend " + " Content-Type " + str(req_data['Content-Type']) + " to host " + HTTP_HOST_OUTGOING )
        ###r_send = send_get(HTTP_URL_OUTGOING,req_data['Content-Type'],r_data)
    ###print("00001----00000----00001")
    #r_data = json.loads(r_send)    
    #response = app.make_response(r_data['r_text'])
    #response.status_code = int(r_data['r_code'])
    #response = app.response_class(
    #    status=int(r_data['r_code']),
    #    response=r_data['r_text']
    #)
    #response.headers
    print("-------------------------------" + " R_END " + "-------------------------------")
    return r_data 

    
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=ENV_DEBUG)
