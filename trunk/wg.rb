# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# see http://www.gnu.org/licenses/gpl-3.0.txt

# == Synopsis
#
# wg.rb: a scalable, opensource and reliable wordlist generator
#
# == Usage
#
# wg.rb configfile action ...
#
# Visit project page at 
#   http://code.google.com/p/ruby-words-generators
#   http://raa.ruby-lang.org/project/ruby-wg/
#
# == Author ==
#
# Matteo Redaelli
# Web site: http://www.redaelli.org/matteo
# Blog: http://www.redaelli.org/matteo/blog/

require 'rubygems'
require 'stomp'
require 'logger'
require 'yaml'
require "socket"
   

####################################################################################
# class WG
# WG is the core of ruby-wg
#
#
####################################################################################
class WG
  def initialize( configfile )
    @logger = Logger.new(STDERR)
    @logger.level = Logger::DEBUG

    @CONFIG = YAML::load(File.read(configfile))

    @hostname = Socket.gethostname
    @pid = Process.pid.to_s
    
    ####################################################################################
    # JMS settings
    ####################################################################################
    jms_hostname =         @CONFIG['settings']['jms']['hostname']
    jms_port =             @CONFIG['settings']['jms']['port']
    jms_user =             @CONFIG['settings']['jms']['user']
    jms_password =         @CONFIG['settings']['jms']['password']

    @logger.info("Logging to JMS broker #{jms_hostname}:#{jms_port}")
    @jms_connection =  Stomp::Connection.open(jms_user, jms_password, jms_hostname, jms_port, false)
    if not @jms_connection
      @logger.info("Cannot connect to JMS broker")
      exit(2)
    else
      @logger.info("..logged! #{@jms_connection}")
    end
    @jms_candidate_words_queue = @CONFIG['settings']['jms']['candidate_words_queue']
    @jms_processed_words_queue = @CONFIG['settings']['jms']['processed_words_queue']
    @jms_results_queue =         @CONFIG['settings']['jms']['results_queue']

    ####################################################################################
    # wg settings
    ####################################################################################
    @splitter_options =      @CONFIG['settings']['wg']['splitter_options']
    @splitter_key_value =    @CONFIG['settings']['wg']['splitter_key_value']
    @dump_results_file =     @CONFIG['settings']['wg']['dump_results_file'] + ".#{@hostname}.#{@pid}"
    @max_run_iterations =    @CONFIG['settings']['wg']['max_run_iterations'].to_i

    @logger.warn("dump_results_file: #{@dump_results_file}")
    @logger.warn("splitter_options: #{@splitter_options}")
    @logger.warn("splitter_key_value: #{@splitter_key_value}")
    @logger.debug("max_run_iterations: #{@max_run_iterations}")

    ####################################################################################
    # wordlist settings
    ####################################################################################
    @characters =                @CONFIG['settings']['wordlist']['characters'].split('')
    @min_length =                @CONFIG['settings']['wordlist']['min_length'].to_i
    @max_length =                @CONFIG['settings']['wordlist']['max_length'].to_i
    @max_consecutive_chars =     @CONFIG['settings']['wordlist']['max_consecutive_chars'].to_i
    @prefix_string =             @CONFIG['settings']['wordlist']['prefix_string'] || ''
    @postfix_string =            @CONFIG['settings']['wordlist']['postfix_string'] || ''
    @regexp_list = @CONFIG['settings']['wordlist']['regexp_list'].split("\n").map do |row|
      fields = row.split(@splitter_options)
      [fields[0], Regexp.new(fields[1])]
    end

    @logger.debug("characters: #{@characters}")
    @logger.debug("regexp_list: #{@regexp_list}")

    @min_char_occurs = Hash.new
    for s in @CONFIG['settings']['wordlist']['min_char_occurs'].split(@splitter_options)
      entry = s.split(@splitter_key_value)
      value = entry[1].to_i
      for char in entry[0].split('')
        @min_char_occurs[char] = value
      end
    end
    @logger.debug("min_char_occurs: #{@min_char_occurs}")
    
    @max_char_occurs = Hash.new
    for s in @CONFIG['settings']['wordlist']['max_char_occurs'].split(@splitter_options)
      entry = s.split(@splitter_key_value)
      value = entry[1].to_i
      for char in entry[0].split('')
        @max_char_occurs[char] = value
      end
    end
    @logger.debug("max_char_occurs: #{@max_char_occurs}")
    
    
    @min_char_list_occurs = Hash.new
    for s in @CONFIG['settings']['wordlist']['min_char_list_occurs'].split(@splitter_options)
      entry = s.split(@splitter_key_value)
      value = entry[1].to_i
      @min_char_list_occurs[entry[0]] = value
    end
    @logger.debug("min_char_list_occurs: #{@min_char_list_occurs}")
    
    @max_char_list_occurs = Hash.new
    for s in @CONFIG['settings']['wordlist']['max_char_list_occurs'].split(@splitter_options)
      entry = s.split(@splitter_key_value)
      value = entry[1].to_i
      @max_char_list_occurs[entry[0]] = value
    end
    @logger.debug("max_char_list_occurs: #{@max_char_list_occurs}")
  end

  ####################################################################################
  # 
  # ACTION check
  # 
  ####################################################################################
  def check
    @logger.info("Check")
  end

  ####################################################################################
  # 
  # ACTION init
  # 
  ####################################################################################
  def init
    @logger.info("Adding empty string as candidate")
    @jms_connection.send(@jms_candidate_words_queue, '', :persistent => true)
  end

  ####################################################################################
  # 
  # ACTION dump_results
  # 
  ####################################################################################
  def dump_results
    @logger.info("Dumping results to file #{@dump_results_file}")
    @jms_connection.subscribe(@jms_results_queue)

    # receive a string
    @logger.info("DUMP Results:")

    for runs in 1..@max_run_iterations
      result = @jms_connection.receive.body
      @logger.debug("dumping result no. #{runs}: string #{result}")
      File.open(@dump_results_file, 'a') {|f| f.write(result.to_s + "\n") }
      $stderr.flush
    end 
  end

  ####################################################################################
  # 
  # ACTION dump_processed
  # 
  ####################################################################################
  def dump_processed
    @jms_connection.subscribe(@jms_processed_words_queue )
    # receive a string
    @logger.info("DUMP processed strings")

    for runs in 1..@max_run_iterations
      result = @jms_connection.receive.body
      @logger.debug("dumping processed no. #{runs}: string #{result}")
      $stdout.puts result
      $stderr.flush
    end 
    @jms_connection.disconnect
  end

  ####################################################################################
  # VALID methods 
  ####################################################################################  
  def valid_min_length?(string)
    l = string.length
    if l < @min_length
      @logger.debug("'#{string}' is too small.")
      return false 
    end
    return true
  end
 
  def valid_max_consecutive_chars?(string)
    chars = string.split('').uniq
    chars.each do |char|
      consecutive_chars = char * (@max_consecutive_chars + 1)
      if string.include?(consecutive_chars)
        @logger.debug("'#{string}' has too many consecutive chars ('#{consecutive_chars}').")
        return false
      end
    return true
  end
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
  
  def valid_regexp?(string)
    for regexp_row in @regexp_list

      include_exclude = regexp_row[0]
      regexp =  regexp_row[1]
      
      case include_exclude
      when "i":
          if not string =~ regexp
            @logger.debug("'#{string}' does not satify include regexp")
            return false
          end
      when "e":
          if string =~ regexp
            @logger.debug("'#{string}' does not satify include and/or exclude regexps")
            return false
          end
      else
        @logger.debug("'#{include_exclude}' must be one of 'i' or 'e'")  
      end
    end
    return true
  end
  
  def valid_word?( string)
    valid_regexp?(string) and 
      valid_min_length?(string) and 
      valid_min_char_occurs?(string, @min_char_occurs) and 
      valid_min_char_occurs?(string, @min_char_list_occurs)
  end


  ####################################################################################
  # 
  # ACTION run
  # 
  ####################################################################################
  
  def run
    # getting candidate strings (<= length-1 from) JMS
    @jms_connection.subscribe( @jms_candidate_words_queue )
    
    # receive a string for at most 'max_run_iterations' parameter
    for runs in 1..@max_run_iterations

      @logger.debug("Iteratation: #{runs} of #{@max_run_iterations}")

      string = @jms_connection.receive.body
      @logger.info("Processing word #{string}")
     
      if string.length >= @max_length
        @logger.debug("'#{string}' has reached the max length (#{@max_length})")
      else
        # generating new words candidates appending to the candidate word
        # each char from 'characters' parameter
        for char in @characters
          @logger.debug("Adding '#{char}' to word '#{string}'")
          newstring = string + char.to_s
          # here i should put some checks (max occur could be done here)
          if not valid_max_char_occurs?(newstring, @max_char_occurs)
            @logger.debug("'#{newstring}' has riched max_char_occurs")
          elsif not valid_max_consecutive_chars?(newstring)
            @logger.debug("'#{newstring}' has riched max_consecutive_chars")
          elsif not valid_max_char_occurs?(newstring, @max_char_list_occurs)
            @logger.debug("'#{newstring}' has riched max_char_list_occurs")
          else
            # send the new string to JMS candidate
            @logger.warn("******* Adding candidate: #{newstring}")
            @jms_connection.send(@jms_candidate_words_queue, newstring,:persistent => true )
            if valid_word?( newstring)
              good_word = @prefix_string + newstring + @postfix_string
              @logger.warn(">>>>>>>>>>  Adding word: #{good_word}")
              @jms_connection.send(@jms_results_queue, good_word,:persistent => true ) 
            end
          end 
        end # iterate characters
      end
      # the string has been processed
      @jms_connection.send( @jms_processed_words_queue, "#{string} by #{@hostname}:#{@pid}") 
      $stdout.flush
      $stderr.flush
    end # listen to candidate queue
    @logger.warn("RUN finished. Done '#{@max_run_iterations}' iterations")  
  end # def run

end # class

########################################################################################
# MAIN
########################################################################################

exit if __FILE__ != $0

def usage
  puts ""
  puts "Usage #{$0} configfile check|init|dump_results|dump_processed|run"
end

if ARGV.length != 2
  usage
  exit 1
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
when "check"
  wg.check
when "dump_processed"
  wg.dump_processed
when "dump_results"
  wg.dump_results
when "init"
  wg.init
when "run"
  wg.run
else
  STDERR.puts "Unknown action #{action}"
  usage
  exit 3
end
