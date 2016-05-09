require 'rubygems'
require 'json'
require 'date'
require 'yaml'
require 'sqlite3'
require './pardotapi'
@connection = Pardotapi.new

if ARGV[0] != nil
  @dt_range = ARGV[0].to_i
else
  @dt_range = 7
end

@passwords = YAML.load(File.read("config/password.yaml"))
@db = SQLite3::Database.new("database/pardot.db")

@days2 = Time.now - (18.5 * 60 * 60)
@days1time = Time.now - (24 * 60 * 60)

@days1 = @days1time.strftime('%Y-%m-%d %H:%M:%S')

report_data_file = File.read('config/report_data.json')
@report_data = JSON.parse(report_data_file)

def get_leads()
    @db.results_as_hash = true
    
    @d1 = Time.now
    @d0 = Time.now - (24 * 60 * 60)
    @resultA = Array.new
    
    results_db = {}
    month_report = {}
    @db.results_as_hash = true
    sql = "SELECT strftime('%m',`Date`) AS month_nbr, lead_type, sum(total) AS sum_month from leads_by_month where date > datetime('now','start of month','-11 month') group by strftime('%Y',`Date`), strftime('%m',`Date`), lead_type order by strftime('%Y',`Date`), strftime('%m',`Date`)"
    checkp = @db.execute(sql)
    checkp.each do |row|
        month_report[row["month_nbr"]] = [row["sum_month"]]
        results_db[row["month_nbr"] + '-' + row["lead_type"]] = row["sum_month"]
    end
    
    leads_array = []
    leads_type = ["BPC","MAT","TIR","3%"]
    
    month_report.keys.uniq.each do |mnth|
        if results_db[mnth + '-3% Lead'] !=nil
            three_percent = results_db[mnth + '-3% Lead']
            else
            three_percent = 0
        end
        
        if results_db[mnth + '-IC Lead'] !=nil
            ic_lead = results_db[mnth + '-IC Lead']
            else
            ic_lead = 0
        end

        leaderboard_row2 = [mnth, results_db[mnth + '-BPC Lead'], results_db[mnth + '-MAT Lead'],results_db[mnth + '-TIR Lead'],three_percent, ic_lead ]
        leads_array << leaderboard_row2
    end
    
    db2_value = {:rows => leads_array}
    
    File.open("json_files/leads_by_month.json", "w") { |f| f.write(db2_value.to_json) }
    
    cmd = 'curl --user ' +  @passwords["klipfolio_email"] + ':' + @passwords["klipfolio_password"] + ' --form file=@json_files/leads_by_month.json https://app.klipfolio.com/api/1.0/datasource/964cc98bc1d150a4aa1a4b9d9a939712/data'

    system(cmd)
end

def get_mailable()
    a = Date.parse("2015-05-10")
    b = DateTime.now - 1
    c = b.mjd - a.mjd 
    d = (c/@dt_range.to_i * @dt_range)
    e = (b - d).strftime('%Y-%m-%d')
    p e

    @db.results_as_hash = true
    
    @d1 = Time.now
    @d0 = Time.now - (24 * 60 * 60)
    @resultA = Array.new
    
    results_db = {}
    month_report = {}
    @db.results_as_hash = true
    sql = "select date ,count from date_count where report = 'mailable' and date >= '#{e}'"
    p sql
    mail_array = []
    checkp = @db.execute(sql)
    cnt = 0
    checkp.each do |row|
       if cnt % @dt_range == 0
         mail_array << [row["date"],row["count"]]
       end
       cnt += 1 
    end

    p mail_array
    db2_value = {:rows => mail_array}

    File.open("json_files/mailable_chart.json", "w") { |f| f.write(db2_value.to_json) }
    
    cmd = 'curl --user ' +  @passwords["klipfolio_email"] + ':' + @passwords["klipfolio_password"] + ' --form file=@json_files/mailable_chart.json https://app.klipfolio.com/api/1.0/datasource/f5ae233210272fdf310175184b55b509/data'
    system(cmd)
end

def get_sm_tracker()
    a = Date.parse("2015-05-10")
    b = DateTime.now - 1
    c = b.mjd - a.mjd 
    d = (c/@dt_range.to_i * @dt_range)
    e = (b - d).strftime('%Y-%m-%d')
    p e

    @db.results_as_hash = true
    
    @d1 = Time.now
    @d0 = Time.now - (24 * 60 * 60)
    @resultA = Array.new
    
    results_db = {}
    month_report = {}
    @db.results_as_hash = true
    #sql = "select date ,count from date_count where report = 'mailable' and date >= '#{e}'"
    sql = "select count(SM_Source_Tracker) as sm_count, SM_Source_Tracker  from prospects where SM_Source_Tracker != 'false | false | false' and SM_Source_Tracker != '' group by SM_Source_Tracker"
    p sql
    sm_array = []
    leader_array = []
    checkp = @db.execute(sql)
    cnt = 0
    checkp.each do |row|
        p row["sm_count"]
        p row["SM_Source_Tracker"].split("/").first
        sm_array << [row["SM_Source_Tracker"].split("/").first,row["sm_count"]]
	leaderboard_row = {:name => row["SM_Source_Tracker"].split("/").first, :values => [row["sm_count"]]}
      leader_array << leaderboard_row
      # if cnt % @dt_range == 0
      #   mail_array << [row["date"],row["count"]]
      # end
      # cnt += 1 
    end


    db_value = {:value => {:board => leader_array}}
    p db_value
#    db2_value = {:rows => sm_array}

    File.open("json_files/sm_tracker.json", "w") { |f| f.write(db_value.to_json) }
    

    cmd = 'curl --user ' +  @passwords["klipfolio_email"] + ':' + @passwords["klipfolio_password"] + ' --form file=@json_files/sm_tracker.json https://app.klipfolio.com/api/1.0/datasource/f5ae233210272fdf310175184b55b509/data'
    system(cmd)
end

get_leads
get_mailable
get_sm_tracker

