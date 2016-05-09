# This ruby script calls facebook graph api to get data for campaigns, spend and clicks and outputs that data 
# to the klipfolio dash board
require 'csv'
require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'nokogiri'
require 'yaml'

@passwords = YAML.load(File.read("config/password.yaml"))

def get_fb_data(date_preset) # this method calls the facebook graph api
  uri = URI.parse("https://graph.facebook.com/v2.3/act_350965832/reportstats?date_preset=#{date_preset}&data_columns=['campaign_group_name','clicks','spend']&access_token=#{@passwords["facebook_access_token"]}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri)
  p request
  response = http.request(request)
  p response.body
  fb_data = JSON.parse(response.body)
  return fb_data
end

results_hash1 = Hash.new
results = get_fb_data('yesterday') # this calls the method for data for last 7 days
results["data"].each do |fbs| # loop through api response and create a hash
  results_hash1[fbs["campaign_group_name"]] = [fbs["spend"],fbs["clicks"]]
end

campaigns_list = results_hash1.keys.uniq

leader_array2 = []
campaigns_list.each do |st| # loop thru hash and output data in json format for klipfilio
  results_hash1[st] != nil ? v1 = '$' + results_hash1[st][0].to_s : v1 = '$0.0' # get spend value
  results_hash1[st] != nil ? v2 = results_hash1[st][1] : v2 = 0 # get clicks
  leaderboard_row2 = {:name => st, :values => [v1, v2, ""]}
  leader_array2 << leaderboard_row2
end

austin_time =  (Time.now + (2 * 60 * 60)).strftime('%H:%M %m-%d') + ' CDT'
leaderboard_row = {:name => austin_time, :values => ["", "", ""]}
leader_array2 << leaderboard_row

db_value = {:value => {:board => leader_array2}}
p db_value
# create a json file and then push that data to klipfolio
File.open("json_files/fb_cam_clicks.json", "w") { |f| f.write(db_value.to_json) }
cmd = 'curl --user ' +  @passwords["klipfolio_email"] + ':' + @passwords["klipfolio_password"] + ' --form file=@json_files/fb_cam_clicks.json https://app.klipfolio.com/api/1.0/datasource/fd1ac7618f22466c521b84a8bc4cfc3d/data'
system(cmd)
