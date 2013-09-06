#!/bin/bash
clear

#Directory / Variable & URL Declerations
LOGS=/root/veportal
HOSTNAME=`hostname`

# Latest TAR & SQL URL's
FILEVEFILES=http://mirror.veportal.com/version2/2/vefiles.tar
FILEMYSQL=http://mirror.veportal.com/version2/1/sql/veportalv2.sql
FILESUPHP=http://mirror.veportal.com/version2/1/modules/suphp-0.7.1.tar.gz
FILEIONCUBE64=http://mirror.veportal.com/version2/1/modules/64bit/ioncube.tar
FILEIONCUBE32=http://mirror.veportal.com/version2/1/modules/32bit/ioncube.tar
FILEOVZ64=http://mirror.veportal.com/version2/1/modules/64bit/ovzinstall.sh
FILEOVZ32=http://mirror.veportal.com/version2/1/modules/32bit/ovzinstall.sh
FILEVZDUMP=http://www.veportal.com/files/v2/vzdump-1.1-2.noarch.rpm
FILECSTREAM64=http://www.veportal.com/files/v2/64bit/cstream-2.7.4-3.el5.rf.x86_64.rpm
FILECSTREAM32=http://www.veportal.com/files/v2/32bit/cstream-2.7.4-3.el5.rf.i386.rpm
FILELIBMCRYPT64=http://www.veportal.com/files/v2/64bit/libmcrypt-2.5.8-4.el5.centos.x86_64.rpm
FILELIBMCRYPT32=http://www.veportal.com/files/v2/32bit/libmcrypt-2.5.8-4.el5.centos.i386.rpm
FILEPHPMCRYPT64=http://www.veportal.com/files/v2/64bit/php-mcrypt-5.1.6-15.el5.centos.1.x86_64.rpm
FILEPHPMCRYPT32=http://www.veportal.com/files/v2/32bit/php-mcrypt-5.1.6-15.el5.centos.1.i386.rpm
FILEVZTOP=http://www.veportal.com/files/v2/vzprocps-2.0.11-6.13.swsoft.i386.rpm
FILEBLANKDBINFO=http://mirror.veportal.com/version2/1/blanks/dbinfo.new
FILESYSCONF=http://mirror.veportal.com/version2/1/conf/sysctl.conf
FILESUPHPCONF=http://mirror.veportal.com/version2/1/conf/suphp.conf
FILEHTTPDCONF=http://mirror.veportal.com/version2/1/conf/httpd.conf
FILEVEPORTALCONF=http://mirror.veportal.com/version2/1/conf/veportal.conf
FILEOSTIMPORT=http://mirror.veportal.com/version2/1/modules/ostImport.vep
FILEVZCONF=http://mirror.veportal.com/version2/1/conf/vz.conf
FILEVZTEMP=http://mirror.veportal.com/version2/1/conf/ve-veportal.conf-sample
FILECRONS=http://mirror.veportal.com/version2/1/conf/defaultcron

# Detect OS Bit
ARCH=`uname -i`
if [ $ARCH == "x86_64" ]; then
	OSBIT=64
else
	OSBIT=32
fi

# Text color variables
TXT_BLD=$(tput bold)
TXT_RED=$(tput setaf 1)
TXT_GREEN=$(tput setaf 2)
TXT_YLW=$(tput setaf 3)
TXT_BLUE=$(tput setaf 4)
TXT_RESET=$(tput sgr0)

# Generate Random MySQL Password
function randpass
{
echo `</dev/urandom tr -dc A-Za-z0-9 | head -c18`
}
SQLPASS=`randpass`

# v2 Splash Screen in Blue with Red Text
echo "${TXT_GREEN}ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo"
echo "${TXT_GREEN}oo ${TXT_YLW}            _____            _         _        ___  ${TXT_RESET}  ${TXT_GREEN} oo"
echo "${TXT_GREEN}oo ${TXT_YLW}           |  __ \          | |       | |      |__ \ ${TXT_RESET}  ${TXT_GREEN} oo"
echo "${TXT_GREEN}oo ${TXT_YLW} __   _____| |__) |___  _ __| |_  __ _| | __   __ ) |${TXT_RESET}  ${TXT_GREEN} oo"
echo "${TXT_GREEN}oo ${TXT_YLW} \ \ / / _ \  ___// _ \| '__| __|/ _\` | | \ \ / // / ${TXT_RESET}  ${TXT_GREEN} oo"
echo "${TXT_GREEN}oo ${TXT_YLW}  \ V /  __/ |   | (_) | |  | |_| (_| | |  \ V // /_ ${TXT_RESET}  ${TXT_GREEN} oo"
echo "${TXT_GREEN}oo ${TXT_YLW}   \_/ \___|_|    \___/|_|   \__|\__,_|_|   \_/|____|${TXT_RESET}  ${TXT_GREEN} oo"
echo "${TXT_GREEN}oo ${TXT_YLW}                                                     ${TXT_RESET}  ${TXT_GREEN} oo"
echo "${TXT_GREEN}ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo"
echo "${TXT_GREEN}oo                                                        ${TXT_GREEN} oo"
echo "${TXT_GREEN}oo               ${TXT_YLW}Version 2.2.100 Installer${TXT_RESET}                ${TXT_GREEN} oo"
echo "${TXT_GREEN}oo                                                        ${TXT_GREEN} oo"
echo "${TXT_GREEN}ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo"
echo "${TXT_RESET}"

# Check That Running OS Is a RHEL Clone or RHEL
if [[ -f /etc/redhat-release ]]; then
    echo "${TXT_BLD}${TXT_GREEN}RHEL or clone OS detected, ready to install!${TXT_RESET}"
else
    echo "${TXT_BLD}${TXT_RED}The installer currently supports RHEL and clones eg- CentOS/Fedora only! Please use the manual installation method."
    exit;
fi

# Check that Server isn't Already running vePortal
if [ -e "/webdisk1/panel/userconf/dbinfo.php" ]; then
    echo "${TXT_BLD}${TXT_RED}Previous vePortal (v1.x -> v2.0.x) Install Detected, Exiting Installer, Please use The vePortal upgrade scripts.${TXT_RESET}"
    exit;
fi
        
if [ -e "/usr/local/veportal/gui/userconf/dbinfo.php" ]; then
    echo "${TXT_BLD}${TXT_RED}Previous vePortal (v2.1.x) Install Detected, Exiting Installer, Please use The vePortal upgrade scripts.${TXT_RESET}"
    exit;
fi

echo -n "${TXT_BLD}${TXT_YLW}The installer will modify your system. Press Enter to continue or Ctrl+C to quit...${TXT_RESET}"
read GO

echo "${TXT_BLD}${TXT_YLW}During this installation it may appear that the console has stopped responding, A Complete log of your install can be found in /root/veportal. Please be patient, The installer will inform you of any changes, Depending on your system specification some processes may take several minutes to complete.${TXT_RESET}"

# Create vePortal Install Logs DIR
mkdir $LOGS &> /dev/null

# Start Installation

# Step1: OpenVZ
# ==============================================================================

        if [ -e "/etc/vz/vz.conf" ]; then
            OVZINST=SKIP
            echo "${TXT_BLUE}Step 1:${TXT_RED} OpenVZ: Already Installed, Moving On${TXT_RESET}"
        else
            OVZINST=OK
            echo "${TXT_BLUE}Step 1:${TXT_RED} OpenVZ: Installing Latest Version${TXT_RESET}"
            if [ $OSBIT == "64" ]; then
                wget $FILEOVZ64 &> $LOGS/get_ovzinstaller64.log
                mv /etc/sysctl.conf /etc/sysctl.conf.vesave
                wget $FILESYSCONF &> $LOGS/get_sysctlconf.log
                mv sysctl.conf /etc/sysctl.conf
                
                rm -fr /vz/template/centos &> /dev/null
                rm -fr /vz/template/fedora &> /dev/null
                rm -fr /vz/template/fedora-core &> /dev/null
                
            else
                wget $FILEOVZ32 &> $LOGS/get_ovzinstaller32.log
            fi

	# NEW OPENVZ INSTALLATION INSTRUCTION

	#Download & Import OpenVZ Repo
	/usr/bin/wget http://download.openvz.org/openvz.repo &> $LOGS/ovz2_install.log
	/bin/mv openvz.repo /etc/yum.repos.d/
	/bin/rpm --import http://download.openvz.org/RPM-GPG-Key-OpenVZ &> $LOGS/ovz2_install.log

	#Install OpenVZ from Repo
	/usr/bin/yum -y install vzkernel &> $LOGS/ovz2_install.log
	/usr/bin/yum -y install vzctl vzquota &> $LOGS/ovz2_install.log
        
        /bin/mv /etc/vz/vz.conf /etc/vz/vz.conf.old &> /dev/null
        
        /usr/bin/wget --directory-prefix=/etc/vz/ $FILEVZCONF &> $LOGS/get_vzconf.log
        /usr/bin/wget --directory-prefix=/etc/vz/conf/ $FILEVZTEMP &> $LOGS/get_vztemplate.log
        
        fi
    
    rm -fr vzprocps-2.0.11-6.13.swsoft.i386.rpm &> /dev/null
    
#    echo " " >> /etc/vz/vz.conf
#    echo "## IPv4 iptables kernel modules" >> /etc/vz/vz.conf
#    echo "IPTABLES="ipt_REJECT ipt_tos ipt_TOS ipt_LOG ip_conntrack ipt_conntrack ip_conntrack_ftp ipt_limit ipt_multiport iptable_filter iptable_mangle ipt_TCPMSS ipt_tcpmss ipt_ttl ipt_length ipt_state iptable_nat ip_nat_ftp ipt_owner ipt_REDIRECT ipt_recent"" >> /etc/vz/vz.conf

    
# Step2: Install VZDump for Backups
# ==============================================================================
    echo "${TXT_BLUE}Step 2: ${TXT_RED}Installing vePortal Backup System for ${OSBIT}bit OS${TXT_RESET}"
    yum -y install MTA &> $LOGS/install_mta.log
    if [ $OSBIT == "64" ]; then
        wget $FILECSTREAM64 &> $LOGS/get_cstreamrpm64.log
    else
        wget $FILECSTREAM32 &> $LOGS/get_cstreamrpm32.log
    fi

    wget $FILEVZDUMP &> $LOGS/get_vzdumprpm.log

    rpm -ivh cstream*.rpm &> $LOGS/install_cstream.log
    rpm -ivh vzdump*.rpm &> $LOGS/install_vzdump.log

    rm -fr cstream*.rpm
    rm -fr vzdump*.rpm

# Step 3: Install Dependant Software
# ==============================================================================
    echo "${TXT_BLUE}Step 3:${TXT_RED} Installing Dependancies for ${OSBIT}bit OS${TXT_RESET}"

    yum -y install sendmail mysqld php httpd php-mysql php-mcrypt php-mbstring php-mysql mysql-devel mysql-server nano httpd-devel mysql-server nano httpd-devel php-cli gcc-c++ openssl mod_ssl expect make gd php-gd &> $LOGS/yum_installs.log
    if [ $OSBIT == "64" ]; then
	wget $FILELIBMCRYPT64 &> $LOGS/get_libmcript.log
	wget $FILEPHPMCRYPT64 &> $LOGS/get_phpmcrypt.log
    else
	wget $FILELIBMCRYPT32 &> $LOGS/get_libmcrypt.log
	wget $FILEPHPMCRYPT32 &> $LOGS/get_phpmcrypt.log
    fi
    rpm -ivh libmcrypt*.rpm &> $LOGS/install_libmcrypt.log
    rpm -ich php-mcypt*.rpm &> $LOGS/install_phpmcrypt.log
    
    rm -fr libmcrypt*.rpm
    rm -fr php-mcrypt*.rpm
    
# Step 4: Install suPHP
# ==============================================================================
    echo "${TXT_BLUE}Step 4:${TXT_RED} Installing suPHP${TXT_RESET}"
    WHOAMI=`whoami`;
    
    # Adding user/group    
        for i in veportal; do
                grep "^$i:" /etc/group >/dev/null
        if [ $? -ne 0 ]; then
            # echo "Couldn't find $i group in /etc/group"
            groupadd veportal
        else
            sleep 1
            # echo "Group already exists, moving on"
        fi                        
            for i in veportal; do
        	    grep "^$i:" /etc/passwd >/dev/null
            if [ $? -ne 0 ]; then
                # echo "Couldn't find $i user in /etc/passwd"	
	        useradd -g veportal -d /usr/local/veportal veportal
            else
                sleep 1
                # echo "User already exists, moving on"
	    fi
        done
    
    # Installing suPHP Files
	wget $FILESUPHP &> $LOGS/get_suphp.log
	tar -zxf suphp-0.7.1.tar.gz &> /dev/null
	cd suphp-0.7.1
	./configure --quiet --prefix=/usr --sysconfdir=/etc --with-apr=/usr/bin/apr-1-config --with-apxs=/usr/sbin/apxs --with-apache-user=apache --with-setid-mode=paranoid --with-php=/usr/bin/php-cgi --with-logfile=/var/log/httpd/suphp_log --enable-SUPHP_USE_USERGROUP=yes &> $LOGS/configure_suphp.log	
	
	sleep 1
	make &> $LOGS/make_suphp.log
	make install &> $LOGS/makeinstall_suphp.log
	
	touch /var/log/httpd/suphp_log
	cd /etc
	wget $FILESUPHPCONF &> $LOGS/get_suphpconfig.log
	touch /etc/httpd/conf.d/suphp.conf
	echo LoadModule suphp_module modules/mod_suphp.so >> /etc/httpd/conf.d/suphp.conf
	echo suPHP_Engine on >> /etc/httpd/conf.d/suphp.conf
	echo AddHandler x-httpd-php .php >> /etc/httpd/conf.d/suphp.conf
	echo suPHP_AddHandler x-httpd-php >> /etc/httpd/conf.d/suphp.conf
	sed -i 's|LoadModule php5_module modules/libphp5.so|#LoadModule php5_module modules/libphp5.so|g' /etc/httpd/conf.d/php.conf
	cd /
	done
	
	#Delete TAR & Directory
	    rm -fr suphp-0.7.1.tar
	    rm -fr suphp-0.7.1
	
# Step 5: Install & Configure Ioncube
# ==============================================================================
    echo "${TXT_BLUE}Step 5:${TXT_RED} Installing Ioncube for ${OSBIT}bit OS${TXT_RESET}"
    if [ $OSBIT == "64" ]; then
	wget $FILEIONCUBE64 &> $LOGS/get_ioncube64.log
	PHPMOD=/usr/lib64/php/modules
    else
	wget $FILEIONCUBE32 &> $LOGS/get_ioncube32.log
	PHPMOD=/usr/lib/php/modules
    fi

    # Determine PHP Version
        PHPVER=`php -r 'echo phpversion();'`
        PHPVER=${PHPVER:0:3}

    # Extract & Move Ioncube Loaders to Module Directory    
        tar -xvf ioncube.tar &> /dev/null
        mv ioncube_* $PHPMOD/
        rm -fr ioncube*
        
    # Add Extension to PHP.ini
	echo "zend_extension=$PHPMOD/ioncube_loader_lin_$PHPVER.so" >> /etc/php.ini
    
# Step 6: Configure Sudoers 
# ==============================================================================
    echo "${TXT_BLUE}Step 6:${TXT_RED} Configuring Sudoers${TXT_RESET}"
    perl -pi -e "s/Defaults    requiretty/\# Defaults     requiretty/g" /etc/sudoers
    echo "veportal        ALL=NOPASSWD: /usr/sbin/vzcalc, /usr/sbin/vzcfgvalidate, /usr/sbin/vzcpucheck, /usr/sbin/vzctl, /usr/sbin/vzdqcheck, /usr/sbin/vzdqdump, /usr/sbin/vzdqload, /usr/sbin/vzdump, /usr/sbin/vzlist, /usr/sbin/vzmemcheck, /usr/sbin/vzmigrate, /usr/sbin/vznetaddbr, /usr/sbin/vznetcfg, /usr/sbin/vzpid, /usr/sbin/vzquota, /usr/sbin/vzsplit, /bin/sh, /usr/bin/wget, /vz/template/cache" >> /etc/sudoers
    

# Step 7: Configure Apache/HTTPD 
# ==============================================================================
    echo "${TXT_BLUE}Step 7:${TXT_RED} Configuring Apache${TXT_RESET}"
    wget $FILEHTTPDCONF &> $LOGS/get_httpdconf.log
    wget $FILEVEPORTALCONF &> $LOGS/get_veportalconf.log    
    mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.vebackup
    mv httpd.conf /etc/httpd/conf/httpd.conf
    mv veportal.conf /etc/httpd/conf.d/veportal.conf
    
# Step 8: Install MySQL User & Dependancys
# ==============================================================================
    echo "${TXT_BLUE}Step 8:${TXT_RED} Configuring MySQL${TXT_RESET}"
    wget $FILEMYSQL &> $LOGS/get_veportalsql.log
    echo "update user set password=PASSWORD(\"$SQLPASS\") where User='root';" >> newsqlpass.sql
    /etc/init.d/mysqld stop &> /dev/null
    mysqld_safe --skip-grant-tables &> /dev/null &
    sleep 5
    /usr/bin/mysql -u root mysql < newsqlpass.sql &> /dev/null
    /etc/init.d/mysqld restart &> /dev/null
    rm -fr newsqlpass.sql
    /usr/bin/mysqladmin -u root password $SQLPASS
    
    /usr/bin/mysql -u root -p$SQLPASS < veportalv2.sql
    
    wget $FILEBLANKDBINFO &> $LOGS/get_dbinfo.log
    mv dbinfo.new dbinfo.php
    perl -pi -e "s/--DBPASS--/$SQLPASS/g" dbinfo.php
    

# Step 9: Deploy Latest Fileset & Place DBInfo.php
# ==============================================================================
    echo "${TXT_BLUE}Step 9:${TXT_RED} File Deployment${TXT_RESET}"
    wget $FILEVEFILES &> $LOGS/get_veportalfiles.log
    tar -xf vefiles.tar -C /; &> $LOGS/deployfiles.log
    rm -fr vefiles.tar
    mkdir /usr/local/veportal/gui/userconf
#    mkdir /usr/local/veportal/ssl
    
    mv dbinfo.php /usr/local/veportal/gui/userconf/dbinfo.php
    
    rm -fr /usr/local/veportal/logs/actions/welcome.txt
    
    mv /usr/local/veportal/skel /vz/skel
    ln -s /vz/skel /usr/local/veportal/skel
    
#    wget $FILECRONS &> $LOGS/download_cronset.log
#    /usr/bin/crontab defaultcron
#    rm -fr defaultcron
    
# Step 10: Set Custom Commands & Configure Services
# ==============================================================================
    echo "${TXT_BLUE}Step 10:${TXT_RED} Customised Commands & Service Configuration${TXT_RESET}"
    chmod +x /etc/init.d/veportal
    chmod +x /usr/sbin/vekick /usr/sbin/vepasswd /usr/sbin/veadminip /usr/sbin/velicense /usr/sbin/veupdate
    
    chkconfig httpd on
    chkconfig mysqld on

    /etc/init.d/httpd restart &> /dev/null
    /etc/init.d/mysqld restart &> /dev/null
    /etc/init.d/network restart &> /dev/null
    
# Step 11: Install & Configure VZTop
# ==============================================================================
    echo "${TXT_BLUE}Step 11:${TXT_RED} Install VZTop${TXT_RESET}"
    wget $FILEVZTOP &> $LOGS/get_vztop.log
    rpm -ivh vzprocps-2.0.11-6.13.swsoft.i386.rpm &> $LOGS/install_vztop.log
    rm -fr vzprocps-2.0.11-6.13.swsoft.i386.rpm
    
# Step 12: Set Permissions on vePortal Files
# ==============================================================================
    echo "${TXT_BLUE}Step 12:${TXT_RED} Setting Permissions${TXT_RESET}"
    mkdir /usr/local/veportal/ssl
    chown -R veportal:veportal /usr/local/veportal
    chown -R veportal:veportal /var/lib/php/session
    chown veportal:veportal /etc/vz/vz.conf
    chown veportal:veportal /etc/vz/conf/ve-veportal.conf-sample
    
# Step 13: Import Old OS Templates
# ==============================================================================
    echo "${TXT_BLUE}Step 13:${TXT_RED} Import Old OS Templates${TXT_RESET}"
    
    wget $FILEOSTIMPORT &> $LOGS/get_osimport.log
    mv ostImport.vep ostImport.php &> /dev/null
    /usr/bin/php ostImport.php &> $LOGS/import_ostemplates.log
    rm -fr ostImport.php &> /dev/null
    

# Step 14: Setup RRDTool
# ==============================================================================
    echo "${TXT_BLUE}Step 14:${TXT_RED} Installing & Configuring RRDTool${TXT_RESET}"

	if [ $OSBIT == "32" ]; then
        	wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.i386.rpm &> $LOGS/setup_rpmforge.log
	else
        	wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm &> $LOGS/setup_rpmforge.log
	fi

	mv rpmforge-release*.rpm /etc/yum.repos.d >> $LOGS/setup_rpmforge.log
	cd /etc/yum.repos.d >> $LOGS/setup_rpmforge.log
	rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt >> $LOGS/setup_rpmforge.log
	rpm -K rpmforge-release-0.5.2-2.el5.rf.*.rpm >> $LOGS/setup_rpmforge.log
	rpm -i rpmforge-release-0.5.2-2.el5.rf.*.rpm >> $LOGS/setup_rpmforge.log

	yum -y install rrdtool *rrd* --skip-broken  >> $LOGS/setup_rrdtool.log
	echo " " >> /etc/php.ini
	echo "extension=\"rrdtool.so\"" >> /etc/php.ini

# Step 15: Cleanup Files & Display Completion Message
# ==============================================================================
    echo "${TXT_BLUE}Step 15:${TXT_RED} Removing Temporary Files & Finalising Installation${TXT_RESET}"
    rm -fr install.sh
    rm -fr suphp*
    rm -fr *.rpm
    rm -fr *.sql
    rm -fr *.tar
    
    echo " ${TXT_BLD}${TXT_GREEN}"
    echo "Your vePortal Installation has been completed. You may now login to your control panel at http://$HOSTNAME:2407"
    echo "On first login you will be prompted to change your password and accept our End User License Agreement."
    echo "If you experience any issues you should check your $LOGS directory for the complete Installation Log Set."
    echo " "
    echo "You may login to your control panel using these credentials"
    echo "${TXT_RED}Hostname: ${TXT_YLW}http://$HOSTNAME:2407"
    echo "${TXT_RED}Username: ${TXT_YLW}admin"
    echo "${TXT_RED}Password: ${TXT_YLW}admin"
    echo "${TXT_RED}MySQL Root Password: ${TXT_YLW}$SQLPASS"
    echo " "
    echo "${TXT_GREEN}Installation Proceedure Completed, Loading Command Prompt"
    sleep 0.5
    echo "${TXT_RED} ."
    sleep 0.5
    echo "${TXT_YLW} .."
    sleep 0.5
    echo "${TXT_GREEN} ..."
    sleep 0.5
    echo "${TXT_BLUE} ...."
    sleep 0.5
    echo "${TXT_RESET} Done..."
