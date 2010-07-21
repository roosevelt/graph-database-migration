require 'rubygems'
require 'mysql'
require 'json'

user= 'root'
pass= ''
host= 'localhost'
db_name='holmes'

mysql_db = Mysql.new(host, user, pass)
mysql_db.select_db(db_name)
select_result = mysql_db.query('SELECT widget_id,json_config, type FROM widget')

update_counter = 0
delete_counter = 0

puts 'Widget table backup started...'

timestamp = String(Time.now.to_i)
mysqldump = IO.popen("mysqldump -u -p holmes widget > widget-" + timestamp + ".sql")
Process.waitpid(mysqldump.pid)

puts "Widget table backup finished. widget-" +  timestamp + ".sql backup file was created into the directory this script was executed."

while row = select_result.fetch_row do 
    if row[1] != nil
        json_config = JSON row[1]  

        chart_type = json_config['chart']      

        json_config.delete('chart')    
        json_config.delete('behaviour')                
        json_config.delete('numEventsToDisplay')
        json_config.delete('dataview-json')
        json_config['labelType'] = 'dynamic'  
        json_str = JSON.dump(json_config)

        case chart_type
	        when 'column'       
                update_res = mysql_db.query("UPDATE widget SET json_config='" + json_str + "', type='ExtFlotBarChart' WHERE widget_id=" + row[0])
                update_counter+=1
	        when 'pie-raphaeljs'
                update_res = mysql_db.query("UPDATE widget SET json_config='" + json_str + "', type='ExtFlotPieChart' WHERE widget_id=" + row[0])
                update_counter+=1
            when 'line'
                update_res = mysql_db.query("UPDATE widget SET json_config='" + json_str + "', type='ExtFlotLineChart' WHERE widget_id=" + row[0])
                update_counter+=1
            when 'dataview'
                delete_result = mysql_db.query("DELETE FROM widget WHERE widget_id=" + row[0])
                delete_counter+=1
            else       
	        end 

        if row[2] == 'LineChart'
            json_config.delete('numDivisions') 
            json_config['labelType'] = 'static'
            json_str = JSON.dump(json_config)
            update_res = mysql_db.query("UPDATE widget SET json_config='" + json_str + "', type='ExtFlotLineChart' WHERE widget_id=" + row[0])
            update_counter+=1
        end
    end     
end

puts String(update_counter) + ' updated rows, ' + String(delete_counter) + ' removed rows'  

select_result.free
mysql_db.close
