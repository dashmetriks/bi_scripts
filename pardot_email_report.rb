# this script calls the pardot visitorActivity api to the totals for each type 
require './pardotapi'
require 'nokogiri'
require 'csv'
require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'nokogiri'
require 'yaml'
require './pardotapi'

@connection = Pardotapi.new

@passwords = YAML.load(File.read("config/password.yaml"))
@api_key = @connection.get_pardot_api_key("get_pardot_api_key")


def get_email_stats(type,t1,t2)
  payload = "api_key=#{@api_key}&user_key=#{@passwords["pardot_user_key"]}&output=full&format=xml&created_after=#{t1}&created_before=#{t2}&type=#{type}"
  uri = URI.parse("https://pi.pardot.com/api/visitorActivity/version/3/do/query?")
  doc = @connection.callapi(payload,uri)
  return doc
end


report_types = Hash["Emails Sent" => 6 , "Clicks" => 1, "Bounced" => 13, "Spam" => 14 , "Opt out" => 12 ]

@days2 = Time.now - (48 * 60 * 60)
@days1 = Time.now - (24 * 60 * 60)
@days0 = Time.now 

hash1 = Hash.new
# this loops through report types hash to get total_results from pardot api and puts that data in a hash
report_types.each do |k,v|
  doc = get_email_stats(v,@days2, @days1)
  total_results1 = doc.css("total_results").inner_text.to_i
  doc = get_email_stats(v,@days1, @days0)
  total_results2 = doc.css("total_results").inner_text.to_i
  hash1[v] = [total_results1, total_results2]
end

leader_array = []
@adverse1 = 0
@adverse2 = 0
# this loops through report types and sums the hash by sent,click, and adverse 
# and outputs the totals for each report type
report_types.each do |k,v|
  v1 = hash1[v][0] 
  v2 = hash1[v][1] 
  if k == "Emails Sent"
    @sent1 = v1
    @sent2 = v2
  end

  if k == "Clicks"
    @click1 = v1
    @click2 = v2
  end

  if [13,14,12].include? v
    @adverse1 = @adverse1 + v1
    @adverse2 = @adverse2 + v2
  end

  if v1.to_i > 0
    p1 = (((v2.to_f / v1.to_f) - 1) *100).to_f.round(2).to_s + '%'
  else
    p1 = ""
  end
  leaderboard_row = {:name => k, :values => [v1, v2, p1]}
  leader_array << leaderboard_row
end

# Click thru Rate is calculated by dividing clicks by sent
v1 = (@click1.to_f / @sent1.to_f * 100).round(2).to_s + '%'
v2 = (@click2.to_f / @sent2.to_f * 100).round(2).to_s + '%'
if v1.to_i > 0
  p1 = (((v2.to_f / v1.to_f) - 1) *100).to_f.round(2).to_s + '%'
else
  p1 = ""
end
leaderboard_row = {:name => "Click thru Rate" , :values => [v1, v2, p1]}
leader_array << leaderboard_row


# Adverse Reaction is calculated by dividing adverse by sent
v1 = (@adverse1.to_f / @sent1.to_f * 100).round(2).to_s + '%'
v2 = (@adverse2.to_f / @sent2.to_f * 100).round(2).to_s + '%'
if v1.to_i > 0
  p1 = (((v2.to_f / v1.to_f) - 1) *100).to_f.round(2).to_s + '%'
else
  p1 = ""
end
leaderboard_row = {:name => "Adverse Reaction" , :values => [v1, v2, p1]}
leader_array << leaderboard_row

austin_time =  (Time.now + (2 * 60 * 60)).strftime('%H:%M %m-%d') + ' CDT'
leaderboard_row = {:name => austin_time, :values => ["", "", ""]}
leader_array << leaderboard_row
db_value = {:value => {:board => leader_array}}
p db_value
File.open("json_files/pardot_email_stats.json", "w"){|f| f.write(db_value.to_json) }


