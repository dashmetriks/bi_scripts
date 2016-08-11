import psycopg2
import numpy as np
try:
    con=psycopg2.connect(dbname= 'analytics', host='redshift-ruby-tutorial.c4w3ie636cnm.us-east-1.redshift.amazonaws.com', port= '5439', user= 'deploy', password= '77Jump88') 
except:
    print "I am unable to connect to the database"
cur = con.cursor()
cur.execute("""select * from users""")
rows = cur.fetchall()
for row in rows:
    print "   ", row

data = np.array(cur.fetchall())
cur.close()
con.close()
