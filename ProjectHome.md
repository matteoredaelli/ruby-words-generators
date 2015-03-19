# About ruby-wg #
Ruby-wg is a opensource scalable and reliable wordlist generator written in Ruby. It uses a stomp broker (like [RabbitMQ](http://www.rabbitmq.com/) or [Apache ActiveMQ](http://activemq.apache.org/)) to store candidate and result words. Ruby-wg can be used to generate a wordlist for [John the Ripper](http://www.openwall.com/john/) or [pyrit](http://code.google.com/p/pyrit/) (which is opensource but you should pay for the wordlist files).

ruby-wg is **scalable**: you can run one or more concurrent "wg.rb run" processes, also from different servers/workstations: in this way the speed will increase with the number of concurrent processes...

ruby-wg is **reliable**: the processes "wg.rb run" run for at most "max\_run\_iterations": when they finish, you can stop/start the (stomp) server and start the "wg.rb run" processes later without missing data and without restarting the wordlist generation from the beginning...

# QuickStart #

See [WikiPage](https://code.google.com/p/ruby-words-generators/wiki/USAGE)

## Alternatives ##

  * perl wg.pl (http://www.redaelli.org/matteo/downloads/perl/wg.pl)
  * erlang ewg (http://www.redaelli.org/matteo-blog/projects/erlang-wordlist-generator-ewg/)

# Architecture #

![http://ruby-words-generators.googlecode.com/svn/trunk/doc/ruby-words-generators.png](http://ruby-words-generators.googlecode.com/svn/trunk/doc/ruby-words-generators.png)

# Features #

Some features:
  * you can run as many concurrent and remote word generators as you want
  * you can "pause" the wordlist generation and go on later (also after a restart of the pc)
  * you can monitor jms queues with Activemq Admin Console and jconsole(.exe)

![http://ruby-words-generators.googlecode.com/svn/trunk/doc/activemq-admin.png](http://ruby-words-generators.googlecode.com/svn/trunk/doc/activemq-admin.png)
![http://ruby-words-generators.googlecode.com/svn/trunk/doc/jconsole.png](http://ruby-words-generators.googlecode.com/svn/trunk/doc/jconsole.png)

Some options (see http://code.google.com/p/ruby-words-generators/source/browse/trunk/settings.yaml.sample for a full list of all supported options):
```
  wg:
    characters: "abc123ABC"
    min_length: 2
    max_length: 6
    max_char_occurs: ab:2
    min_char_occurs: b:1,a:1
    min_char_list_occurs: 1234567890:1,ABCDEFG:1
    max_char_list_occurs: ab:5,c:3,1223:6
    max_run_iterations: 1000
    prefix_string: myprefix
    postfix_string: mytail
    max_consecutive_chars: 2
    regexp_list: |	 
      e,a$
      i,^a
```

# Support #
  * feedbacks and help please join the google group http://groups.google.it/group/ruby-wg
  * bugs and new features: add a **new issue**