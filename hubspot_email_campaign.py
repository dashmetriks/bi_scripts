import urllib2
import json
response = urllib2.urlopen("https://api.hubapi.com/cosemail/v1/emails/listing?offset=0&limit25&access_token=#{access_token}")

data = json.load(response)   
f = ["All Campaigns"]
for i in data["objects"]:
   x = i.get("campaignName","No Campaign")
   f.append(str(x))

camp = sorted(set(f))

db_value = {'list' : camp}
print db_value 
with open('/Users/nest/Downloads/hubspot_email.json', 'w') as f:
    f.write(repr(db_value)) 


