#!/usr/bin/env python3.8
import config
import os
import sys
import telebot
from telebot import types
import psycopg2
from psycopg2 import Error
import jsontree
import json
import requests
from requests.auth import HTTPDigestAuth
import logging
import sentry_sdk
from sentry_sdk.integrations.logging import LoggingIntegration
from sentry_sdk.integrations.logging import ignore_logger
import time
import datetime
## @it_uk_manager_bot /dispatcher_restart



# CONFIGURATION PARAMETERS
treads_count_started = 3
now = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime())
formatted_command = "empty"
log_file_name = "empty"
version = "1.0.0"
allowed_cmds = '^ls,^zfs[\s]+(list|get)'
executor = os.uname()[1]

# ----------OS ENV
TELEGRAM_PROXY_HTTP = os.getenv('TELEGRAM_PROXY_HTTP', 'http://10.26.0.21:8118')
TELEGRAM_PROXY_HTTPS = os.getenv('TELEGRAM_PROXY_HTTPS', 'https://10.26.0.21:8118')
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN', 'BOT_TOKEN')
os.environ["http_proxy"] = TELEGRAM_PROXY_HTTP
os.environ["https_proxy"] = TELEGRAM_PROXY_HTTPS
bot = telebot.TeleBot(TELEGRAM_BOT_TOKEN)
#@it_uk_manager_bot

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ENV PARAMETERS
POSTGRES_DB_HOST = os.getenv('POSTGRES_DB_HOST', 'postgres')
POSTGRES_DB_PORT = os.getenv('POSTGRES_DB_PORT', '5432')
POSTGRES_DB_NAME = os.getenv('POSTGRES_DB_NAME', 'ansible')
POSTGRES_DB_USER = os.getenv('POSTGRES_DB_USER', 'postgres')
POSTGRES_DB_PASSWORD = os.getenv('POSTGRES_DB_PASSWORD', 'hfdf23dfdfj3llL')
POSTGRES_TABLE_NAME_JOBS = os.getenv('POSTGRES_TABLE_NAME_JOBS', 'tbl_ansible_jobs')
POSTGRES_TABLE_NAME_LOGS = os.getenv('POSTGRES_TABLE_NAME_LOGS', 'tbl_ansible_logs')
SCRIPTS_STORE_DIR = os.getenv('SCRIPTS_STORE_DIR', '/tmp')

SENTRY_URL = os.getenv('SENTRY_URL', 'https://abc5140d3a9242b38dbbc6b0136bcf44:f28aa7bc642c4c34a4d253d12e2ldadf@sentry.example.com/2')
SENTRY_SERVER_NAME = os.getenv('SENTRY_SERVER_NAME', executor)

RMPQ_HOST = os.getenv('RMPQ_HOST', 'rabbitmq')
RMPQ_PORT = os.getenv('RMPQ_PORT', '5672')
RMPQ_USER = os.getenv('RMPQ_USER', 'user')
RMPQ_PASSWORD = os.getenv('RMPQ_PASSWORD', 'CfitCyjdf18higuig')
RMPQ_QUEUE = os.getenv('RMPQ_QUEUE', 'ansible_web') 
RMPQ_SSL_OPT = os.getenv('RMPQ_SSL_OPT', 'ansible_web') 
ENV_DEBUG = os.getenv('ENV_DEBUG', 'ansible_web') 

ANSIBLE_API_TRANSFORMATOR = os.getenv('ANSIBLE_API_TRANSFORMATOR', 'http://10.26.0.38:8300/ansible/transformation/api/v1')


logging.getLogger().addHandler(logging.StreamHandler())

executor = os.uname()[1]


sentry_logging = LoggingIntegration(
    level=logging.INFO,        # Capture info and above as breadcrumbs
    event_level=logging.ERROR  # Send errors as events
)

sentry_sdk.init(
    dsn=SENTRY_URL,
    integrations=[sentry_logging],
    server_name=executor
)

### Клавиатура
keyboard1 = telebot.types.ReplyKeyboardMarkup()
keyboard1.row('/dispatcher_restart','/gis_key_update')




def prepare_timescaledb(TIMESCALE_TABLE_NAME):
    try:
        con = psycopg2.connect(host=POSTGRES_DB_HOST, port=POSTGRES_DB_PORT, database=POSTGRES_DB_NAME,
                               user=POSTGRES_DB_USER, password=POSTGRES_DB_PASSWORD
                               )
        con.autocommit = True
    except:
        print('Cant connect to db', file=sys.stderr)
    with con:
        cur = con.cursor()
        query = "CREATE TABLE IF NOT EXISTS %s (time TIMESTAMPTZ NOT NULL,metric_name text not null,data jsonb,value double precision)" % TIMESCALE_TABLE_NAME
        query_index1 = "CREATE INDEX IF NOT exists idxgin_data_%s ON %s USING GIN (data)" % (TIMESCALE_TABLE_NAME,TIMESCALE_TABLE_NAME)
        query_index2 = "CREATE INDEX IF NOT exists idxgin_metric_name_%s ON %s (metric_name)" % (TIMESCALE_TABLE_NAME,TIMESCALE_TABLE_NAME)
        query_hypertable = "SELECT create_hypertable('%s', 'time',migrate_data => true, chunk_time_interval => interval '1 day',if_not_exists => TRUE)" % TIMESCALE_TABLE_NAME
        cur.execute(query,)
        print('Timecale table .. ' + TIMESCALE_TABLE_NAME +
              ' created (if not exist)')
        cur.execute(query_index1,)
        cur.execute(query_index2,)
        print('Timecale table .. ' + TIMESCALE_TABLE_NAME +
          ' created (if not exist) index with name .. ' + 'exists idxgin_tbl ' + TIMESCALE_TABLE_NAME)
        cur.execute(query_hypertable,)
        print('Timecale hypertable .. ' + TIMESCALE_TABLE_NAME + ' created (if not exist',file=sys.stderr)

def send_timescale(metric_name,data,value,POSTGRES_TABLE_NAME_JOBS):
    json_data = jsontree.dumps(data)
    try:
        con = psycopg2.connect(host=POSTGRES_DB_HOST, port=POSTGRES_DB_PORT, database=POSTGRES_DB_NAME,
                                user=POSTGRES_DB_USER, password=POSTGRES_DB_PASSWORD
                            )
        con.autocommit = True
    except:
        print('Cant connect to db',file=sys.stderr)
    pg_timestamp =  datetime.datetime.utcnow()
    #print(json_data,file=sys.stderr) 
    with con:           
        cur = con.cursor()
        query = "INSERT INTO %s (time, metric_name,data,value) VALUES (%%s, %%s, %%s, %%s)" % POSTGRES_TABLE_NAME_JOBS
        cur.execute(query, (pg_timestamp, metric_name,json_data,value))
        #print('Inserted',file=sys.stdout)

### Функция проверки авторизации
def autor(chatid):
    strid = str(chatid)
    print("chatid = " + str(chatid))
    for item in config.users:
        if item == strid:
            return True
    return False

@bot.message_handler(commands=['start'])
def start(message):
    if autor(message.chat.id):
        cid = message.chat.id
        message_text = message.text
        user_id = message.from_user.id
        user_name = message.from_user.first_name
        print("user_id = " + str(user_id))
        print("cid = " + str(cid))
        print("user_name = " + str(user_name))
        #mention = "[" + user_name + "](tg://user?id=" + str(user_id) + ")"
        bot.send_message(message.chat.id, 'Привет, ' + user_name + ' Что ты хочешь от меня?!', reply_markup=keyboard1)
        bot.send_sticker(message.chat.id, 'CAADAgAD6CQAAp7OCwABx40TskPHi3MWBA')
    else:
        bot.send_message(message.chat.id, 'Тебе сюда нельзя. Твой ID: ' + str(message.chat.id))
        bot.send_sticker(message.chat.id, 'CAADAgADcQMAAkmH9Av0tmQ7QhjxLRYE')


@bot.message_handler(commands=['dispatcher_restart'])
def dispatcher_restart_message(message):

    if autor(message.chat.id):
        bot.send_message(message.from_user.id, "Диспатчер какого клиента перезагрузить - введите домен клиента(например kl.it-uk.ru)")
        print('Restart call')

        bot.register_next_step_handler(message, dispatcher_restart)
    else:
        print('403')


def dispatcher_restart(message):
    print(message.text)
    cid = message.chat.id
    message_text = message.text
    user_id = message.from_user.id
    user_name = message.from_user.first_name
    executor = "telegram"
    http_host=''
    http_host = str(message.text)
    ansible_playbook = "/etc/ansible/playbooks/asu_manage/run.yaml"
    ansible_tags = "dispatcher_restart_call"
    
    report_data = {"executor": executor,
                    "user_id": user_id,
                    "user_name": user_name,
                    "message_text":message_text,
                    "cid":cid,
                    "called_job": ansible_playbook + http_host + ansible_tags
                    }
    value = 1
    metric_name = 'telegram_job'
    prepare_timescaledb(POSTGRES_TABLE_NAME_JOBS)
    send_timescale(metric_name,report_data,int(value),POSTGRES_TABLE_NAME_JOBS)
    ansible_extra_vars = "sender=telegram"
    send_post(ansible_playbook,http_host,ansible_tags,ansible_extra_vars)
    message="Диспатчер клиента " + http_host + " отправлен в очередь на перезапуск"
    bot.send_message(user_id, message)


def send_post(ansible_playbook,http_host,ansible_tags,ansible_extra_vars):
    url = ANSIBLE_API_TRANSFORMATOR
    headers = {'Content-type': 'application/json', 'Accept': 'text/plain'}
    payload = {'ansible_playbook': ansible_playbook, 'http_host': http_host, 'ansible_tags': ansible_tags, 'ansible_extra_vars': ansible_extra_vars }
    print('Version .. ' + version)
    print('Post to address .. ' + url)
    print(json.dumps(payload))
    r = requests.post(url,json=payload, headers=headers)
    print(r.status_code, r.reason)



def main():
    bot.polling(none_stop=True, interval=1)
if __name__ == "__main__":
    main()



#https://habr.com/ru/post/442800/