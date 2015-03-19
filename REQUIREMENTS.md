## Ruby ##

Install ruby language >= 1.8 (tested also with 2.1) from http://www.ruby-lang.org (many Linux distributions include it by defaults)

Install rubygems from http://rubyforge.org/frs/?group_id=126: this tool helps you to install easily additional ruby libraries in a fast way (gem install XXX)

Install STOMP library with "gem install stomp"

## Stomp Server ##

I have tested RabbitMQ and ApacheActiveMQ. Choose and install one of them!

## RabbitMQ ##

Download and Install RabbitMQ from http://www.rabbitmq.com/download.html
or, if you have Linux Debianorubuntu, you are like and can simply run

```
apt-get install rabbitmq-server
  
rabbitmq-plugins enable rabbitmq_stomp
```

### Apache Activemq ###

You need Java jdk >= 1.5 (Java 1.6 is better): you can download it from http://java.sun.com/javase/downloads/index.jsp

Set JAVA\_HOME with the path where you installed jdk


Download and install/uncompress a JMS broker like apache activemq (http:://activemq.apache.org) or fuse message broker (http://fusesource.com/downloads/)

```
 wget http://mirror.nohup.it/apache/activemq/apache-activemq/5.4.1/apache-activemq-5.4.1.bin.tar.gz
 tar xvfz apache-activemq-5.4.1-bin.tar.gz
 cd apache-activemq-5.4.1
```

If you are using a Linux/Unix server (see [unix](http://activemq.apache.org/unix-shell-script.html)), you can simply

```
  bin/activemq start xbean:conf/activemq-stomp.xml
```

Otherwise

Check Stomp support in the file conf/activemq.xml: if you find

```
        <transportConnectors>
            <transportConnector name="openwire" uri="tcp://0.0.0.0:61616"/>
        </transportConnectors>
   </broker>
```

Stomp is not enabled and according to http://activemq.apache.org/stomp.html you should add a line in order to have


```
        <transportConnectors>
           <transportConnector name="stomp+nio" uri="stomp+nio://0.0.0.0:61613"/>
        </transportConnectors>
   </broker>
```

Start ActiveMQ

```
 ./bin/activemq-admin start 
```

You can check if activemq and its admin console are available with
> http://localhost:8161/admin/

![http://ruby-words-generators.googlecode.com/svn/trunk/doc/activemq-admin.png](http://ruby-words-generators.googlecode.com/svn/trunk/doc/activemq-admin.png)

The dedicated queues for "wg" will be created when you start wordlist generation the first time. Then you can empty or drop them from the admin comsole