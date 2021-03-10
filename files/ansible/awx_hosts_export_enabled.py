#!/usr/bin/env python3.8
import psycopg2
import os
import yaml

AWX_DB_HOST = os.getenv('AWX_DB_HOST', '10.48.0.101')
AWX_DB_PORT = os.getenv('AWX_DB_PORT', '15432')
AWX_DB_NAME = os.getenv('AWX_DB_NAME', 'awx')
AWX_DB_USER = os.getenv('AWX_DB_USER', 'awx')
AWX_DB_PASSWORD = os.getenv('AWX_DB_PASSWORD', 'awxpasswordnew')
ANSIBLE_HOSTS_FILE = os.getenv('ANSIBLE_HOSTS_FILE', 'hosts')

def iter_row(cursor, size=10):
    while True:
        rows = cursor.fetchmany(size)
        if not rows:
            break
        for row in rows:
            yield row

def getfromPG():
    conn = None
    try:
        conn = psycopg2.connect(user = AWX_DB_USER,
            password = AWX_DB_PASSWORD,
            host = AWX_DB_HOST,
            port = AWX_DB_PORT,
            database = AWX_DB_NAME)
        cur = conn.cursor()
        SQL = "select name,variables,enabled from main_host where enabled = 'true'"
        cur.execute(SQL)
        rows = cur.fetchall()

        open(ANSIBLE_HOSTS_FILE, 'w').close()
        f = open(ANSIBLE_HOSTS_FILE,"a+")
        print("#The number of parts: ", cur.rowcount)
        print("ALLHOSTS:")
        print("  hosts:")
        f.write('ALLHOSTS:\n')
        f.write("  hosts:" + '\n')
        for row in rows:

            awx_host = row[0]
            awx_varaibles = row[1]
            
            awx_host_beaty = awx_host.replace(" ", "" )
            awx_varaibles_beaty = awx_varaibles.replace(" ", "").replace(":", ": " )
            awx_varaibles_beaty_2 = '\n'.join([' '*4 + line for line in awx_varaibles_beaty.split('\n') ])
            awx_var_yml = yaml.dump(yaml.load(awx_varaibles, Loader=yaml.FullLoader), default_flow_style=False)
            awx_varaibles_beaty_3 = '\n'.join([' '*4 + line for line in awx_var_yml.split('\n') ])

            print ('  ' + awx_host_beaty + ':')
            print (awx_varaibles_beaty_2)
            print(yaml.dump(yaml.load(awx_varaibles, Loader=yaml.FullLoader), default_flow_style=False))
            f = open(ANSIBLE_HOSTS_FILE,"a+")
            f.write('   ' + awx_host_beaty + ':'+'\n')
            f.write(awx_varaibles_beaty_3 + '\n')
            f.close() 
            row = cur.fetchone()
        cur.close()
        

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

def main():
    getfromPG()
if __name__ == "__main__":
    main()