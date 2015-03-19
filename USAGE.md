**Before going on, please see [REQUIREMENTS](REQUIREMENTS.md) page**

## Start a JMS server ##

For instance, if you use apache activemq and it is installed in /opt/apache-activemq, run

> /opt/apache-activemq/bin/activemq &

## Setup Wordlist options ##

Create/change a configuration file settings.yaml

## Initialise the generator ##

The first candidate word is an empty string. To put it in the specific queue run

> ruby wg.rb settings.yaml init

## Dump the results ##

To dump the results to a file "wordlist.txt", you need to run
> ruby wg.rb settings.yaml dump\_results >> wordlist.txt

Press Control+c to stop when it finishes or you want to break it

## Run the generators ##

Possibly from different computers, you can run one or more generators

> ruby wg.rb settings.yaml run

## Monitoring the Systems ##

If you use activemq/fuse message broker, you can monitor JMS activity from jconsole command

![http://ruby-words-generators.googlecode.com/svn/trunk/doc/jconsole.png](http://ruby-words-generators.googlecode.com/svn/trunk/doc/jconsole.png)

or from the web console (http://localhost:8161/admin/queues.jsp)

![http://ruby-words-generators.googlecode.com/svn/trunk/doc/activemq-admin.png](http://ruby-words-generators.googlecode.com/svn/trunk/doc/activemq-admin.png)