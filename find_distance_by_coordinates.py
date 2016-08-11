from math import pi,sqrt,sin,cos,atan2
from operator import itemgetter

import json

def haversine(pos1, pos2):
    lat1 = float(pos1['lat'])
    long1 = float(pos1['long'])
    lat2 = float(pos2['lat'])
    long2 = float(pos2['long'])

    degree_to_rad = float(pi / 180.0)

    d_lat = (lat2 - lat1) * degree_to_rad
    d_long = (long2 - long1) * degree_to_rad

    a = pow(sin(d_lat / 2), 2) + cos(lat1 * degree_to_rad) * cos(lat2 * degree_to_rad) * pow(sin(d_long / 2), 2)
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    km = 6367 * c
    mi = 3956 * c

 #   return {"km":km, "miles":mi}
    return km #{"km":km}

file = open('latlong.txt', 'r')
hundred_list =[]
d = {}
for line in file:
    d2 = json.loads(line)
    #print d2['latitude'] + d2['longitude']
    data = dict(pos1={'lat':'53.3381985','long':'-6.2592576'}, pos2={'lat':d2['latitude'],'long':d2['longitude']})
    dist = haversine(**data)
    dd = int(dist)
    if dd <= 101:
      d[d2['user_id']] = d2['name'] 
    
print d

newlist = sorted(d.items(), key=itemgetter(0))     
      
for k, v in newlist:
	print("{0}:{1}".format(k, v))
