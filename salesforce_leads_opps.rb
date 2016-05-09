# this script queries salesforce leads and opportunties and outputs the data to klipfolio
require 'nokogiri'
require 'csv'
require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'nokogiri'
require 'yaml'
require 'sqlite3'
require 'cgi'
require './pardotapi'
@connection = Pardotapi.new
$token = @connection.get_salesforce_api_token
 

@passwords = YAML.load(File.read("config/password.yaml"))
@db = SQLite3::Database.new("database/pardot.db")

p Time.now
@days2 = Time.now - (18.5 * 60 * 60)
@days1time = Time.now - (24 * 60 * 60)

@days1 = @days1time.strftime('%Y-%m-%d %H:%M:%S')

report_data_file = File.read('config/report_data.json')
@report_data = JSON.parse(report_data_file)

def get_leads()
  results = @connection.get_salesforce_data("salesforce_leads")
  @db.results_as_hash = true

  @d1 = Time.now
  @d0 = Time.now - (24 * 60 * 60)
  @resultA = Array.new

  sql1 = "select * from leads where date = '#{@d1.strftime('%Y-%m-%d')}'"
  checkforleads = @db.execute(sql1)
  if checkforleads != []
    sql = "DELETE FROM leads WHERE  date = '#{@d1.strftime('%Y-%m-%d')}'"
    @db.execute(sql);
  end

  results_hash = {}
  results["records"].each do |ops|
    results_hash[ops["Status"]] = ops["expr0"]
    sql = "INSERT INTO leads(lead_status,count,date) VALUES('#{ops["Status"]}', '#{ops["expr0"]}', '#{@d1.strftime('%Y-%m-%d')}') "
    @db.execute(sql);
  end

  lead_status = results_hash.keys.uniq

  results_db = {}
  @db.results_as_hash = true
  sql = "select * from leads where date = '#{@d0.strftime('%Y-%m-%d')}'"
  checkp = @db.execute(sql)
  checkp.each do |row|
    results_db[row["lead_status"]] = row["count"]
  end

  results_hash2 = {}

  leader_array2 = []
  lead_status.each do |st|
    results_db[st] != nil ? v1 = results_db[st] : v1 = 0
    results_hash[st] != nil ? v2 = results_hash[st] : v2 = 0
    p1 = (((v2.to_f / v1.to_f) - 1) *100).to_f.round(2).to_s + '%'
    leaderboard_row2 = {:name => st, :values => [v1, v2, p1]}
    leader_array2 << leaderboard_row2
  end
  austin_time =  (Time.now + (2 * 60 * 60)).strftime('%H:%M %m-%d') + ' CDT'
  leaderboard_row = {:name => austin_time, :values => ["", "", ""]}
  leader_array2 << leaderboard_row


  db_value = {:value => {:board => leader_array2}}
  p db_value
  @connection.send_data_to_dashboard(@db_value,"pardot_mailable_report", @report_data["klip_reports"]["salesforce_leads"]["datasource"])
end

def get_opps()
  results = @connection.get_salesforce_data("salesforce_opps")
  @resultA = Array.new
  results_hash = {}
  results_stage = {}
  results["records"].each do |ops|
    p ops["StageName"] + ops["CloseDate"].to_s + ops["expr0"].to_s
    stage_date = ops["StageName"] + ops["CloseDate"]
    results_hash[stage_date] = ops["expr0"]
    results_stage[ops["StageName"]] = ops["expr0"]
  end

  @d0 = Time.now - (24 * 60 * 60)
  @d1 = Time.now

  dayspan = [@d0.strftime('%Y-%m-%d'), @d1.strftime('%Y-%m-%d')]
  stages = results_stage.keys.uniq

  resultB = Array.new

  results_hash2 = {}
  stages.each do |st|
    dayspan.each do |dy|
      results_hash[st + dy] != nil ? v1 = results_hash[st + dy] : v1 = 0
      results_hash2[st + dy] = v1
    end
  end

  leader_array2 = []
  stages.each do |st|
    v1 = results_hash2[st + dayspan[0]]
    v2 = results_hash2[st + dayspan[1]]
    p1 = (((v2.to_f / v1.to_f) - 1) *100).to_f.round(2).to_s + '%'
    leaderboard_row2 = {:name => st, :values => [v1, v2, p1]}
    leader_array2 << leaderboard_row2
  end
  austin_time =  (Time.now + (2 * 60 * 60)).strftime('%H:%M %m-%d') + ' CDT'
  leaderboard_row = {:name => austin_time, :values => ["", "", ""]}
  leader_array2 << leaderboard_row

  db_value = {:value => {:board => leader_array2}}
  p db_value
  @connection.send_data_to_dashboard(@db_value,"pardot_mailable_report", @report_data["klip_reports"]["salesforce_opps"]["datasource"])
end

get_leads
get_opps
