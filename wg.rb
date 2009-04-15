#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
# any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.
# see http://www.gnu.org/licenses/gpl-3.0.txt

# == Synopsis
#
# wg.rb: greets user, demonstrates command line parsing
#
# == Usage
#
# wg.rb configfile action ...
#
#

require 'rubygems'
require 'stomp'
require 'logger'
require 'yaml'
require "socket"

class WG
  def initialize( configfile )
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG

    @CONFIG = YAML::load(File.read(configfile)) 
      
    @characters = @CONFIG['settings']['wg']['characters'].split('')
    @min_length = @CONFIG['settings']['wg']['min_length'].to_i
    @max_length = @CONFIG['settings']['wg']['max_length'].to_i
    @max_run_iterations = @CONFIG['settings']['wg']['max_run_iterations'].to_i
    
    @prefix_string = @CONFIG['settings']['wg']['prefix_string'] || ''
    @postfix_string = @CONFIG['settings']['wg']['postfix_string'] || ''
    
    @min_char_occurs = Hash.new
    for s in @CONFIG['settings']['wg']['min_char_occurs'].split(',')
      entry = s.split(':')
      value = entry[1].to_i
      for char in entry[0].split('')
        @min_char_occurs[char] = value
      end
    end
    @logger.debug("min_char_occurs: #{@min_char_occurs}")
    
    @max_char_occurs = Hash.new
    for s in @CONFIG['settings']['wg']['max_char_occurs'].split(',')
      entry = s.split(':')
      value = entry[1].to_i
      for char in entry[0].split('')
        @max_char_occurs[char] = value
      end
    end
    @logger.debug("max_char_occurs: #{@max_char_occurs}")
    
    
    @min_char_list_occurs = Hash.new
    for s in @CONFIG['settings']['wg']['min_char_list_occurs'].split(',')
      entry = s.split(':')
      value = entry[1].to_i
      @min_char_list_occurs[entry[0]] = value
    end
    @logger.debug("min_char_list_occurs: #{@min_char_list_occurs}")
    
    @max_char_list_occurs = Hash.new
    for s in @CONFIG['settings']['wg']['max_char_list_occurs'].split(',')
      entry = s.split(':')
      value = entry[1].to_i
      @max_char_list_occurs[entry[0]] = value
    end
    @logger.debug("max_char_list_occurs: #{@max_char_list_occurs}")
    
    # JMS settings
    @jms_hostname = @CONFIG['settings']['jms']['hostname']
    @jms_port = @CONFIG['settings']['jms']['port']
    
    @jms_candidate_words_queue = @CONFIG['settings']['jms']['candidate_words_queue']
    @jms_processed_words_queue = @CONFIG['settings']['jms']['processed_words_queue']
    @jms_results_queue = @CONFIG['settings']['jms']['results_queue']  

  end
  
  def init
    jms_connection = Stomp::Connection.open(@jms_user, @jms_password, @jms_hostname, @jms_port, false)
    jms_connection.send(@jms_candidate_words_queue, '')
    jms_connection.disconnect
  end
  
  def dump_results
    jms_connection = Stomp::Connection.open(@jms_user, @jms_password, @jms_hostname, @jms_port, false)
    jms_connection.subscribe(@jms_results_queue)
    
    # receive a string
    @logger.info("DUMP Results:")
    while true
      result = jms_connection.receive.body
      STDOUT.puts result.to_s
    end
    
    jms_connection.disconnect
    
  end

  def dump_processed
    jms_connection = Stomp::Connection.open(@jms_user, @jms_password, @jms_hostname, @jms_port, false)
    jms_connection.subscribe(@jms_processed_words_queue)
    
    # receive a string
    @logger.info("DUMP processed:")
    while true
      result = jms_connection.receive.body
      STDOUT.puts result
    end
    
    jms_connection.disconnect
    
  end
  
  def valid_min_length?(string)
    l = string.length
    if l < @min_length
      @logger.debug("'#{string}' is too small.")
      return false 
    end
    return true
  end
 
  def valid_min_char_occurs?(string, hash)
    hash.each do |key, value| 
      if string.count(key) < value
        @logger.debug("'#{string}' has too few occurrences (#{value}) of '#{key}'")
        return false        
      end
    end
    return true
  end
  
  def valid_max_char_occurs?(string, hash)
    hash.each do |key, value| 
      if string.count(key) > value
        @logger.debug("'#{string}' has too much occurrences (#{value}) of '#{key}'")
        return false        
      end
    end
    return true
  end
  
  def valid_word?( string)
    valid_min_length?(string) and valid_min_char_occurs?(string, @min_char_occurs) and valid_min_char_occurs?(string, @min_char_list_occurs)
  end
  
  def run
    runs = @max_run_iterations
    jms_connection = Stomp::Connection.open(@jms_user, @jms_password, @jms_hostname, @jms_port, false)
    hostname = Socket.gethostname
    pid = Process.pid

    # gest strings of size length-1 from JMS
    jms_connection.subscribe( @jms_candidate_words_queue )
    
    # receive a string 
    while runs > 0
      runs = runs -1
      string = jms_connection.receive.body
      @logger.info("Processing word #{string}")
     
      if string.length >= @max_length
        @logger.debug("'#{string}' has riched the max length (#{@max_length})")
      else
        for char in @characters
          @logger.debug("Adding '#{char}' to word '#{string}'")
          newstring = char.to_s + string
          
          # here i should put some checks (max occur could be done here)
          if not valid_max_char_occurs?(newstring, @max_char_occurs)
            @logger.debug("'#{newstring}' has riched max_char_occurs")
          elsif not valid_max_char_occurs?(newstring, @max_char_list_occurs)
            @logger.debug("'#{newstring}' has riched max_char_list_occurs")
          else
              # send the new string to JMS candidate             
              jms_connection.send(@jms_candidate_words_queue, newstring)
              jms_connection.send(@jms_results_queue, @prefix_string + newstring + @postfix_string) if valid_word?( newstring)
          end 
        end # iterate characters
      end
      # the string has been processed
      jms_connection.send( @jms_processed_words_queue, "#{string} by #{hostname}:#{pid}") 
    end # listen to candidate queue
    @logger.warn("RUN finished. Done '#{@max_run_iterations}' iterations")  
    jms_connection.disconnect
  end # def run
  

end # class


exit if __FILE__ != $0

def usage
  puts ""
  puts "Usage #{$0} configfile init|dump_results|dump_processed|run"
end

if ARGV.length != 2
  usage
  exit 0
end

configfile = ARGV[0]
action = ARGV[1]

if not FileTest.readable?( configfile )
  STDERR.puts "The file '#{configfile}' doesn't exists or is not readlable"
  usage
  exit 4
end

wg = WG.new( configfile )

case action
when "init"
  wg.init
when "dump_processed"
  wg.dump_processed
when "dump_results"
  wg.dump_results
when "run"
  wg.run
else
  STDERR.puts "Unknown action #{action}"
  usage
  exit 3
end
