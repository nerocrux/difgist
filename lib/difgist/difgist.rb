#!/usr/bin/ruby
require 'rubygems'
require 'rest-client'
require 'json'
require 'optparse'
require 'yaml'

class Difgist

  def initialize(arguments)
    @config_yml = File.expand_path("~/.difgist.yml")
    @diff_file = File.expand_path("~/.difgist.diff")
    @params = ["hostname", "username", "password"]
    @options = {}
    @settings = {}
    load_config
    @optparse = OptionParser.new()
    set_options
    check_options
  end

  def load_config
    config = YAML.load_file(@config_yml)
    is_initialized = true
    @params.each{|key|
      if not config or not config.has_key?(:"#{key}")
        is_initialized = false
        break
      else @settings[:"#{key}"] = config[:"#{key}"]
      end
    }
    if not is_initialized
      init_config
    end
  end

  def init_config
    print "Initializing...\n"
    # hostname
    print "= hit enter if you want yo use github, or enter endpoint url if you use github enterprise =\n"
    print "[hostname]: "
    hostname = gets.strip
    if hostname == "" then @settings[:hostname] = "api.github.com" else @settings[:hostname] = hostname end
    # username
    print "[username]: "
    @settings[:username] = gets.strip
    # password
    print "[password]: "
    @settings[:password] = gets.strip
    # finish
    print "Init done. [username] = #{@settings[:username]}, [hostname] = #{@settings[:hostname]}\n"
    # write to yml
    File.open(@config_yml, "w") {|f| f.write(YAML.dump(@settings)) }
    system("chmod 600 #{@config_yml}")
  end

  def set_options
    @optparse.banner = "Usage: -d --description, -f -file"
    @optparse.on('-d [VALUE]','--description [VALUE]','description option') { |opt| @options[:description] = opt }
    @optparse.on('-f [VALUE]','--file [VALUE]','file option') { |opt| @options[:target_file] = opt }
  end

  def check_options
    if @options[:description] == nil
      then description = "posted by difgist"
    end
    if @options[:target_file] == nil
      then target_file = ""
    else
      if File.exist?(@options[:target_file]) == false
        puts "No such file. Dump all."
        @options[:target_file] = ""
      end
    end
  end

  def run
    begin
      if File.exist?(".svn")
        then
          system("LANG=C svn diff #{@options[:target_file]} > #{@diff_file}")
      elsif system('git rev-parse --is-inside-work-tree >/dev/null 2>&1') == true
        then
          system("git diff #{@options[:target_file]} > #{@diff_file}")
        else
      end

      payload = nil
      File.open(@diff_file, "r") do |f|
        payload = {
          :description => @options[:description],
          :public => true,
          :files => {
            "difgist.diff" => {
              :content => f.read
            }
          }
        }
      response = JSON.parse(RestClient.post("https://#{@settings[:username]}:#{@settings[:password]}@#{@settings[:hostname]}/gists", payload.to_json, :content_type => "text/json"))
      puts "Done. " + response['html_url']
      end
    rescue
      puts "Error."
    end
  end
end
