# upload.rb 
# a simple utility speed up your work with unfuddle
# Created by Shan Ul Haq on 12/01/15
#
# setup your domian, username and password and you are good to go.
# options:
# 	-p to get list of projects
# 	-m <project id> to get the list of milestones for project.
# 	-c <project id> to get the list of components for project
# 	-s <project id> to get the list of severities for project
# 	-v <project id> to get the list of versions for project
# 	-f <project id> to get the list of custom field values for project
# creating tickets:
# 	-t <csv file> <project id> to upload the tickets to unfuddle
# 	first line of the csv file should be the header.
# 	summary, description, hour headers are mandatory to define in the csv file. 
# 	optionally you can put milestone, component, severity, version and priority
# 	in the csv file or if all the tickets have same properties you can defind below in 
# 	UNFUDDLE_SETTINGS properties

require 'csv'
require 'net/https'
require 'json'
begin
  require 'terminal-table'
rescue LoadError
  puts "terminal-table not found"
end

UNFUDDLE_SETTINGS = {
  #-----------------------------
  :subdomain  => ENV['UGIT_UNFUDDLE_DOMAIN'],
  :username   => ENV['UGIT_UNFUDDLE_USERNAME'],
  :password   => ENV['UGIT_UNFUDDLE_PASSWORD'],
  #-----------------------------  
  :ssl        => true,

  # you can set the project_id here and then you do not have to pass it from command line.
  :project_id => ENV['UGIT_UNFUDDLE_PROJECT'],

  #set the below values for creating your tickets. If you have mentioned these properties in your
  # csv file, then those values will take precedence over the values defined here.
  #---------------------
  :milestone  => '<#milestone id#>',
  :component_id => '<#component id#>',
  :severity_id	=> '<#severity id#>',
  :version_id	=> '<#version id#>',
  :priority	=> '<#priority#>'
  #---------------------
}

$http = Net::HTTP.new("#{UNFUDDLE_SETTINGS[:subdomain]}.unfuddle.com", UNFUDDLE_SETTINGS[:ssl] ? 443 : 80)

# if using ssl, then set it up
if UNFUDDLE_SETTINGS[:ssl]
  $http.use_ssl = true
  $http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

def search_project(query)
  # perform an HTTP GET
  begin
    if !UNFUDDLE_SETTINGS[:project_id].nil?
      request = Net::HTTP::Get.new("/api/v1/projects/#{UNFUDDLE_SETTINGS[:project_id]}/search.json?query=#{query}&filter=tickets")
    else
      request = Net::HTTP::Get.new("/api/v1/account/search.json?query=#{query}&filter=tickets")
    end
    request.basic_auth UNFUDDLE_SETTINGS[:username], UNFUDDLE_SETTINGS[:password]
    response = $http.request(request)
    if response.code == "200"
      beautify_s(response.body, "Summary")
    else
      # hmmm...we must have done something wrong
      puts "HTTP Status Code: #{response.code}."
      return nil
    end
  rescue => e
    puts e
    return nil
  end  
end

def get_response(type)
  # perform an HTTP GET
  begin
    if(type == 'projects')
      request = Net::HTTP::Get.new("/api/v1/projects.json")
    else
      request = Net::HTTP::Get.new("/api/v1/projects/#{UNFUDDLE_SETTINGS[:project_id]}/#{type}.json")
    end
    request.basic_auth UNFUDDLE_SETTINGS[:username], UNFUDDLE_SETTINGS[:password]

    response = $http.request(request)
    if response.code == "200"
      return response.body
    else
      # hmmm...we must have done something wrong
      puts "HTTP Status Code: #{response.code}."
      return nil
    end
  rescue => e
    puts e
    return nil
  end
end

def get_projects
    beautify_m get_response('projects'), 'Projects'
end

def get_milestones
    beautify_m get_response('milestones'), 'Milestones'
end

def get_components
    beautify_c get_response('components'), 'Components'
end

def get_serverities
    beautify_c get_response('severities'), 'Severities'
end

def get_versions
    beautify_c get_response('versions'), 'Versions'
end

def get_custom_field_values
    beautify_f get_response('custom_field_values'), 'Custom Field Values'
end


def beautify_m(output, title)
  json_out = JSON.parse(output)
  rows = []
  json_out.each do |m|
    rows << [m['title'], m['id']]
  end
  table = Terminal::Table.new :rows => rows, :headings => ['Name', 'Id'], :title => title
  puts table
end

def beautify_s(output, title)
  json_out = JSON.parse(output)
  tickets = Array.new
  json_out.each do |m|
    ['type', 'description', 'total_count', 'status', 'updated_at'].each { |k| m.delete k }
    tickets.push(m)
  end
  puts tickets.to_json
  # table = Terminal::Table.new :rows => rows, :headings => ['Summary'], :title => title
  # puts table
end

def beautify_c(output, title)
  json_out = JSON.parse(output)
  rows = []
  json_out.each do |m|
    rows << [m['name'], m['id']]
  end
  table = Terminal::Table.new :rows => rows, :headings => ['Name', 'Id'], :title => title
  puts table
end

def beautify_f(output, title)
  json_out = JSON.parse(output)
  rows = []
  current_field = nil
  json_out.each do |m|
  	new_field = m['field_number']
    rows << [m['field_number'], m['value'], m['id']]
    if(new_field != current_field and !current_field.nil?)
    	rows << :separator
    end
    current_field = new_field
  end
  table = Terminal::Table.new :rows => rows, :headings => ['Field Number', 'Value' , 'Id'], :title => title
  puts table
end


def create_ticket(project_id, summary, description, milestone, priority, component_id, hours, severity_id, version_id)
	begin
	  request = Net::HTTP::Post.new("/api/v1/projects/#{project_id}/tickets", 
	  								{'Content-type' => 'application/xml'})
	  request.basic_auth UNFUDDLE_SETTINGS[:username], UNFUDDLE_SETTINGS[:password]
	  request.body = "<ticket><description><![CDATA[#{description}]]></description>
	  							<milestone-id type='integer'>#{milestone}</milestone-id>
	  							<priority>#{priority}</priority>
	  							<summary><![CDATA[#{summary}]]></summary>
	  							<component-id type='integer'>#{component_id}</component-id>
	  							<hours-estimate-initial type='float'>#{hours}</hours-estimate-initial>
	  							<hours-estimate-current type='float'>#{hours}</hours-estimate-current>
	  							<severity-id type='integer'>#{severity_id}</severity-id>
	  							<version-id type='integer'>#{version_id}</version-id>
	  				 </ticket>"
	  response = $http.request(request)
	  if response.code == "201"
	    puts "Ticket Created: #{response['Location']}"
	  else
	    # hmmm...we must have done something wrong
	    puts "HTTP Status Code: #{response.body}."
	  end
	rescue => e
	  # do something smart
	  puts e
	end
end

def update_ticket_status(project_id, ticket_id, resolved, commit_message)
  begin
    request = Net::HTTP::Put.new("/api/v1/projects/#{project_id}/tickets/#{ticket_id}", 
                    {'Content-type' => 'application/xml'})
    request.basic_auth UNFUDDLE_SETTINGS[:username], UNFUDDLE_SETTINGS[:password]
    if(resolved.eql? "1")
      request.body = "<ticket><status>resolved</status><resolution>fixed</resolution>"
      if(!commit_message.nil?)
        request.body << "<resolution-description>commit hash : #{commit_message}</resolution-description>"
      end
      request.body << "</ticket>"
    else
      request.body = "<ticket><status>wip</status></ticket>"
    end
    response = $http.request(request)
    if response.code == "200"
      puts "Ticket Created: #{response['Location']}"
    else
      # hmmm...we must have done something wrong
      puts "HTTP Status Code: #{response.body}."
    end
  rescue => e
    # do something smart
    puts e
  end
end

def add_time_entry(project_id, ticket_id, hour, message)
  begin
    request = Net::HTTP::Post.new("/api/v1/projects/#{project_id}/tickets/#{ticket_id}/time_entries", 
                    {'Content-type' => 'application/xml'})
    request.basic_auth UNFUDDLE_SETTINGS[:username], UNFUDDLE_SETTINGS[:password]
    
    date = Date.parse(Time.now.to_s)
    date.strftime("%Y-%m-%d")

    request.body = "<time-entry>
        <hours type='float'>#{hour}</hours>"
    if(!message.nil?)
      request.body << "<description>#{message}</description>"
    else
      request.body << "<description>work done</description>"
    end
    request.body << "<date type='date'>#{date}</date>"
    request.body << "</time-entry>"

    response = $http.request(request)
    if response.code == "201"
      puts "Ticket Created: #{response['Location']}"
    else
      # hmmm...we must have done something wrong
      puts "HTTP Status Code: #{response.body}."
    end
  rescue => e
    # do something smart
    puts e
  end
end

def create_tickets(csv_file)
	if csv_file.nil? or !File.exists? csv_file
		puts 'no file found'
		return
	end
	csv = CSV.foreach(csv_file, :headers => :first_row, :return_headers => false) do |row|
		create_ticket UNFUDDLE_SETTINGS[:project_id], 
						row['summary'], 
						row['description'], 
						row['milestone'].nil? ? UNFUDDLE_SETTINGS[:milestone] : row['milestone'],
						row['priority'].nil? ? UNFUDDLE_SETTINGS[:priority] : row['priority'],
						row['component'].nil? ? UNFUDDLE_SETTINGS[:component_id] : row['component'],
						row['hour'],
						row['serverity'].nil? ? UNFUDDLE_SETTINGS[:severity_id] : row['serverity'],
						row['version'].nil? ? UNFUDDLE_SETTINGS[:version_id] : row['version']
	end
end

#set the project id if available
if(ARGV[0] != '-t')
	project_id = ARGV[1]
else
	project_id = ARGV[2]
end
if(!project_id.nil?)
	UNFUDDLE_SETTINGS[:project_id] = project_id
end

if ARGV[0] == '-m'
  get_milestones
elsif ARGV[0] == '-c'
  get_components
elsif ARGV[0] == '-s'
  get_serverities
elsif ARGV[0] == '-v'
  get_versions
elsif ARGV[0] == '-p'
  get_projects
elsif ARGV[0] == '-t'
  create_tickets(ARGV[1])
elsif ARGV[0] == '-f'
  get_custom_field_values
elsif ARGV[0] == '-u'
  update_ticket_status(ARGV[1], ARGV[2], ARGV[3], ARGV[4])
elsif ARGV[0] == '-a'
  add_time_entry(ARGV[1], ARGV[2], ARGV[3], ARGV[4])
else
  search_project ARGV[0]
end