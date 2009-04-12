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
require 'yaml'


class WG
  def initialize( configfile )
    @CONFIG = YAML::load(File.read(configfile)) 
      
    @characters = @CONFIG['settings']['wg']['characters'].split('')
    @min_length = @CONFIG['settings']['wg']['min_length'].to_i
    @max_length = @CONFIG['settings']['wg']['max_length'].to_i
    
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
    STDERR.puts "DUMP Results:"
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
    STDERR.puts "DUMP processed words:"
    while true
      result = jms_connection.receive.body
      STDOUT.puts result
    end
    
    jms_connection.disconnect
    
  end
  
  def valid_word?( string)
    l = string.length
    return false if l < @min_length or l > @max_length
      
    return true
  end
  
  def run
    jms_connection = Stomp::Connection.open(@jms_user, @jms_password, @jms_hostname, @jms_port, false)

    # gest strings of size length-1 from JMS
    jms_connection.subscribe( @jms_candidate_words_queue )
    
    # receive a string 
    while true
      string = jms_connection.receive.body
      STDERR.puts "Processing word #{string}"
     
      if string.length < @max_length
        for char in @characters
            newstring = char.to_s + string
            # here i should put some checks (max occur could be done here)
            # send the new string to JMS candidate 
            jms_connection.send(@jms_candidate_words_queue, newstring)
            jms_connection.send(@jms_results_queue, newstring) if valid_word?( newstring)
        end # iterate characters
      end
      # the string has been processed
      jms_connection.send( @jms_processed_words_queue, string) 
    end # listen to candidate queue
      
    jms_connection.disconnect
  end

end # class


exit if __FILE__ != $0

def usage
  puts "Usage $0 configfile init|dump_results|dump_processed|run"
end
if ARGV.length != 2
  usage
  exit 0
end

configfile = ARGV[0]
action = ARGV[1]

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
