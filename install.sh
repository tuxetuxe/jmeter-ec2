#!/bin/bash
#
# jmeter-ec2 - Install Script (Runs on remote ec2 server)
#

# Source the jmeter-ec2.properties file, establishing these constants.
. /tmp/jmeter-ec2.properties

REMOTE_HOME=$1
INSTALL_JAVA=$2
JMETER_VERSION=$3
JMETER_PLUGINS_VERSION=$4

function install_jmeter_plugins() {
    wget -q -O $REMOTE_HOME/JMeterPlugins.jar https://s3.amazonaws.com/jmeter-ec2/JMeterPlugins.jar
    mv $REMOTE_HOME/JMeterPlugins.jar $REMOTE_HOME/$JMETER_VERSION/lib/ext/
    
    #install jmeter plugins from jmeter-plugins.org
    wget -q -O $REMOTE_HOME/JMeterPlugins-Standard-$JMETER_PLUGINS_VERSION.zip http://jmeter-plugins.org/downloads/file/JMeterPlugins-Standard-$JMETER_PLUGINS_VERSION.zip
    unzip $REMOTE_HOME/JMeterPlugins-Standard-$JMETER_PLUGINS_VERSION.zip -d $REMOTE_HOME/JMeterPlugins-Standard-$JMETER_PLUGINS_VERSION/
    rsync -a $REMOTE_HOME/JMeterPlugins-Standard-$JMETER_PLUGINS_VERSION/ $REMOTE_HOME/$JMETER_VERSION/
    
    wget -q -O $REMOTE_HOME/JMeterPlugins-Extras-$JMETER_PLUGINS_VERSION.zip http://jmeter-plugins.org/downloads/file/JMeterPlugins-Extras-$JMETER_PLUGINS_VERSION.zip
    unzip $REMOTE_HOME/JMeterPlugins-Extras-$JMETER_PLUGINS_VERSION.zip -d $REMOTE_HOME/JMeterPlugins-Extras-$JMETER_PLUGINS_VERSION/
    rsync -a $REMOTE_HOME/JMeterPlugins-Extras-$JMETER_PLUGINS_VERSION/ $REMOTE_HOME/$JMETER_VERSION/
    
    wget -q -O $REMOTE_HOME/JMeterPlugins-ExtrasLibs-$JMETER_PLUGINS_VERSION.zip http://jmeter-plugins.org/downloads/file/JMeterPlugins-ExtrasLibs-$JMETER_PLUGINS_VERSION.zip
    unzip $REMOTE_HOME/JMeterPlugins-ExtrasLibs-$JMETER_PLUGINS_VERSION.zip -d $REMOTE_HOME/JMeterPlugins-ExtrasLibs-$JMETER_PLUGINS_VERSION/
    rsync -a $REMOTE_HOME/JMeterPlugins-ExtrasLibs-$JMETER_PLUGINS_VERSION/ $REMOTE_HOME/$JMETER_VERSION/
    
    wget -q -O $REMOTE_HOME/JMeterPlugins-WebDriver-$JMETER_PLUGINS_VERSION.zip http://jmeter-plugins.org/downloads/file/JMeterPlugins-WebDriver-$JMETER_PLUGINS_VERSION.zip
    unzip $REMOTE_HOME/JMeterPlugins-WebDriver-$JMETER_PLUGINS_VERSION.zip -d $REMOTE_HOME/JMeterPlugins-WebDriver-$JMETER_PLUGINS_VERSION/
    rsync -a $REMOTE_HOME/JMeterPlugins-WebDriver-$JMETER_PLUGINS_VERSION/ $REMOTE_HOME/$JMETER_VERSION/
    
    wget -q -O $REMOTE_HOME/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/2.8/chromedriver_linux64.zip
    mkdir -p $REMOTE_HOME/$JMETER_VERSION/drivers/chromedriver
    unzip $REMOTE_HOME/chromedriver_linux64.zip -d $REMOTE_HOME/$JMETER_VERSION/drivers/chromedriver

}

function install_google_chrome(){
	wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy -f install
	wait
}

function install_xvfb(){
	sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy install xvfb xfonts-100dpi xfonts-75dpi xfonts-scalable
	wait
	
	XVFB=/usr/bin/Xvfb
	XVFBARGS=":1 -screen 0 1920x1200x24 -ac +extension GLX +render -noreset"
	PIDFILE=/var/run/xvfb.pid

	start-stop-daemon --start --quiet --pidfile $PIDFILE --make-pidfile --background --exec $XVFB -- $XVFBARGS
	
	export DISPLAY=:99
	
}

function install_mysql_driver() {
    wget -q -O $REMOTE_HOME/mysql-connector-java-5.1.16-bin.jar https://s3.amazonaws.com/jmeter-ec2/mysql-connector-java-5.1.16-bin.jar
    mv $REMOTE_HOME/mysql-connector-java-5.1.16-bin.jar $REMOTE_HOME/$JMETER_VERSION/lib/
}


cd $REMOTE_HOME

#install utilities
sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy install unzip
wait

if [ $INSTALL_JAVA -eq 1 ] ; then
    # install java
	
	#ubuntu
	sudo apt-get update #update apt-get
	sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy install default-jre
	wait
fi

# install jmeter
case "$JMETER_VERSION" in

jakarta-jmeter-2.5.1)
    # JMeter version 2.5.1
    wget -q -O $REMOTE_HOME/$JMETER_VERSION.tgz http://archive.apache.org/dist/jmeter/binaries/$JMETER_VERSION.tgz
    tar -xf $REMOTE_HOME/$JMETER_VERSION.tgz
    # install jmeter-plugins [http://code.google.com/p/jmeter-plugins/]
    install_jmeter_plugins
    # install mysql jdbc driver
	install_mysql_driver
	install_google_chrome
	install_xvfb
    ;;

apache-jmeter-*)
    # JMeter version 2.x
    wget -q -O $REMOTE_HOME/$JMETER_VERSION.tgz http://archive.apache.org/dist/jmeter/binaries/$JMETER_VERSION.tgz
    tar -xf $REMOTE_HOME/$JMETER_VERSION.tgz
    # install jmeter-plugins [http://code.google.com/p/jmeter-plugins/]
    install_jmeter_plugins
    # install mysql jdbc driver
	install_mysql_driver
	install_google_chrome
	install_xvfb
    ;;
    
*)
    echo "Please check the value of JMETER_VERSION in the properties file, $JMETER_VERSION is not recognised."
esac

echo "software installed"
