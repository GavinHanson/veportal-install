#!/bin/bash
##########################################################################
#  SETX86_64
#  (C) 2007-2009 Manuel Carreira
#  Under GNU General Public License
   Version=0.5
#########################################################################
#  This script provides the automatic installation of openvz utilities 
#  and template utilities,  in a x86_64 RPM BASED SYSTEM
#  like Centos/RHEL/Fedora system, applying some patches to allow them to work
#  as described in the wiki page:
#  http://wiki.openvz.org/Install_OpenVZ_on_a_x86_64_system_Centos-Fedora
#########################################################################

versiontested=("CentOS release 4" "CentOS release 5" "Fedora Core release 5" "Fedora Core release 6")
#  vztemplates database
# Centos 4
distr[0]="centos"
dver[0]=4
templOS[0]="http://download.openvz.org/template/metadata/centos-4/vztmpl-centos-4-2.0-2.i386.rpm"
# Centos 5
distr[1]="centos"
dver[1]=5
templOS[1]="-k http://forum.openvz.org/index.php?t=getfile&id=415&" 
# Fedora 3
distr[2]="fedora-core"
dver[2]=3
templOS[2]="http://download.openvz.org/template/metadata/fedora-core-3/vztmpl-fedora-core-3-2.0-2.i386.rpm" 
# Fedora 4
distr[3]="fedora-core"
dver[3]=4
templOS[3]="http://download.openvz.org/template/metadata/fedora-core-4/vztmpl-fedora-core-4-2.0-2.i386.rpm" 
# Fedora 5
distr[4]="fedora-core"
dver[4]=5
templOS[4]="http://download.openvz.org/template/metadata/fedora-core-5/vztmpl-fedora-core-5-2.0-2.i386.rpm" 
# Fedora 6
distr[5]="fedora-core"
dver[5]=6
templOS[5]="http://download.openvz.org/template/metadata/contrib/vztmpl-fedora-core-6-1.2-1.i386.rpm" 
# Fedora 7
distr[6]="fedora"
dver[6]=7
templOS[6]="http://download.openvz.org/template/metadata/contrib/vztmpl-fedora-7-1.1-1.i386.rpm"
# Fedora 9
distr[7]="fedora"
dver[7]=9
templOS[7]="http://forum.openvz.org/index.php?t=getfile&id=620&"


#---------------------------------------------------------------------
#  Preliminary tests
#---------------------------------------------------------------------
osfile="/etc/redhat-release"
OSvers=`grep -s release $osfile`

#  Testing the platform allowing only x86_64 platforms
if [ `uname -i` != "x86_64" ]; then
	echo "This is not a x86_64 platform!"
	echo "Aborted script!"
	exit 1
fi
echo "---------------------------------------------"
echo " Openvz to x86_64 platform (Ver. ${Version})"
echo "---------------------------------------------"
if [ -z "$OSvers" ]; then
	echo "This seems not to be a RedHat based operating system..."
else
	echo "Your OS seems to be........ ${OSvers}"
fi

#  Testing essential programs
cnt=0
for i in "which -V" "yum --version" "python -V" "rpm --version" "patch --version"
do
	$i > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Command not found =>  `echo $i | cut -d' ' -f1`"
		cnt=1
	fi
done
if [ $cnt -gt 0 ]; then
	echo "Install command(s) before running this script"
	exit 1
else
	echo "rpm, yum and python........ Found!"	
fi	

yumversion=`yum -d0 --version | awk 'BEGIN {FS="."}; {print $1$2}'`
if [ $yumversion -lt 24 ]; then
	echo "yum version not supported!"
	echo "Install yum version 2.4 or greater"
	exit 1
fi	
rpmversion=`rpm --version | cut -d' ' -f3 | awk 'BEGIN {FS="."}; {print $1$2}'`
if [ $rpmversion -lt 43 ]; then
	echo "rpm version not supported!"
	echo "Install rpm version 4.3 or newer"
	exit 1
fi	
pyver=`python -c 'import sys; v=sys.version_info; print "%d.%d" % (v[0], v[1])'`
echo -n "Python version... $pyver"

#  Test if python version is compatible with vzrpm 
vercorr=0
for i in "2.2" "2.3" "2.4"
do
	if [ "$i" = "$pyver" ]; then
		vercorr=1
		break
	fi
done
if [ $vercorr -eq 0 ]; then
	echo
	echo "This distro has python version $pyver, which is incompatible with vzrpm"
	echo "Aborted Installation!"
	exit 1
else
	echo "...... OK!"
fi

#  Test rpm-python for x86_64
dirpy=/usr/lib64/python${pyver}/site-packages

if [ -d $dirpy ]; then
	echo "rpm-python for x86_64...... Found!"
else
	echo "rpm-python (x86_64)........ NOT FOUND!"
	echo "Please install rpm-python package before runnning this script"
	echo "Note: this package may have another name in some distros (e.g. python-rpm)"
	echo "Aborted installation!"
	exit 1
fi
YUM=`which yum`
MKDIR=`which mkdir`
WGET=`which wget`
RPM=`which rpm`
SED=`which sed`
CP=`which cp`	

#  Verify if OS distro is a tested one.
h=0
while [ $h -lt ${#versiontested[@]} ]
do
	echo "$OSvers" | grep -qis "${versiontested[h]}"
	if [ $? -eq 0 ]; then
		break
	fi
	h=`expr $h + 1`
done

if [ $h -ge ${#versiontested[@]} ]; then
	echo "---------------------------------------------"
	echo "This operating system was not tested before using this script,"
	echo "but still... it seems to have PASSED ALL TESTS."
	echo "There is a good possibility to be well succeeded."
else
	echo "---------------------------------------------"
	echo "ALL TESTS PASSED!"
fi	
echo
# echo -n "Do you want to go on with the installation? [N/y] "
# read GO_ON

#if ! ([ "$GO_ON" = "Y" ] || [ "$GO_ON" = "y" ]); then
#	echo "Aborted installation by user request!"
#	exit
#fi

GO_ON=Y

#  Install yum openvz.repo if it is not installed yet
if ! [ -f /etc/yum.repos.d/openvz.repo ]; then
	wdir=`pwd`
        cd /etc/yum.repos.d
        $WGET http://download.openvz.org/openvz.repo
        $RPM --import  http://download.openvz.org/RPM-GPG-Key-OpenVZ
        cd $wdir
fi     

#  Install openvz utilities and template utilities
#set -x
dummy= `rpm -qa --nosignature --queryformat "[%{NAME}.%{ARCH}\n]" vzctl | grep x86_64 >/dev/null`
r=$?
if [ $r -eq 1 ]; then
	# Uninstall vzctl.i386 if necessary
	$RPM -e --nodeps vzctl.i386 2>/dev/null
        $YUM -y install vzctl.x86_64
        # Confirm that i386 version is uninstalled
        
fi

dummy= `rpm -qa --nosignature --queryformat "[%{NAME}.%{ARCH}\n]" vzquota | grep x86_64 >/dev/null`
r=$?
if [ $r -eq 1 ]; then
        # Confirm that i386 version is uninstalled, then install x86_64 version
        $RPM -e --nodeps vzquota.i386 2>/dev/null
        $YUM -y install vzquota.x86_64
fi

/etc/rc.d/init.d/vz start > /dev/null

dummy=`$RPM -q vzrpm43 vzrpm44 vzrpm43-python vzrpm44-python`
r=$?
if [ $r -gt 0 ]; then
        $YUM -y install vzrpm*
fi

dummy=`$RPM -q vzyum`
r=$?
if [ $r -eq 1 ]; then
        $WGET -c http://download.openvz.org/template/utils/vzyum/2.4.0-11/vzyum-2.4.0-11.noarch.rpm
        $RPM --nodeps -Uvh vzyum*.rpm
        rm -f vzyum*.rpm
fi
dummy=`$RPM -q vzpkg`
r=$?
if [ $r -eq 1 ]; then
        $YUM -y install vzpkg*
fi        

#--------------------------------------------------------------
#  Create x86_64 template from i386 templates
#--------------------------------------------------------------
template_64()
{
	local bakdir=`pwd`
	cd $dirtempl
	if ! [ -d x86_64 ]; then
	        $MKDIR x86_64
	fi        
	$CP -a ${dirtempl}/i386/* ${dirtempl}/x86_64
	cd ${dirtempl}/x86_64/config
	$SED -i.tmp 's/i386/x86_64/g' yum.conf
	rm -f yum.conf.tmp

	#------------------------------------------------------
	# Change /vz/template/centos/$dver/x86_64/config/yum.conf
	#------------------------------------------------------
	$SED -i.tmp '/^cachedir=/ c\cachedir=\/var\/cache\/yum-cache\/' yum.conf
	rm -f yum.conf.tmp

	#--------------------------------------------------------
	# Change /vz/template/centos/$dver/x86_64/config/minimal.list
	#--------------------------------------------------------
	mkdvver=`ls ${dirtempl}/x86_64/vz-addons/MAKEDEV-3.*.rpm`
	mkdvver=`basename ${mkdvver} | cut -d'-' -f2`
	mkdv="MAKEDEV-${mkdvver}"
	$SED -i.tmp "/^MAKEDEV/ c $mkdv" minimal.list
	rm -f minimal.list.tmp

	#--------------------------------------------------------
	# Change /vz/template/centos/$dver/x86_64/config/default.list
	#--------------------------------------------------------
	$SED -i.tmp "/^MAKEDEV/ c $mkdv" default.list
	rm -f default.list.tmp

	
	#--------------------------------------------------------
	# Correct /vz/template/centos/$dver/x86_64/config/rpm  
	#--------------------------------------------------------
	echo $rpmversion > rpm
	cd $bakdir
}

#  Download all i386 vz templates available
#  and create x86_64 templates
#  Some of then will not work because of python version incompatibilities
#  between host and guests.
#  e.g.  host: centos-5     guest: fedora-core-3   ==> don't work
#  e.g.  host: centos-5     guest: fedora-core-6   ==> work well

echo
echo "Downloading vztemplates......."
olddir=`pwd`
cd /tmp
mkdir templvz.$$
cd templvz.$$
kk=0
err_q=0
while [ $kk -lt ${#templOS[@]} ]
do
	#  Skip this step if template is already installed
	dirtempl="/vz/template/${distr[kk]}/${dver[kk]}"
	if ! [ -f "${dirtempl}/x86_64/config/rpm" ]; then	
		getname=`wget -nv ${templOS[kk]}`
		qq=$?
		echo $getname
		if [ $qq -gt 0 ]; then
			echo " ==> Error downloading..."
			err_q=`expr $err_q + 1`
		else
			if [ $kk -eq 1 ] || [ $kk -eq 7 ]; then
				# as centos-5 and fedora-9 have a linkname, we must change the namefile to the real one
				# because older wget versions dont work as expected with -k argument
				if [ $kk -eq 1 ]; then
				    nameall="vztmpl-centos-5-2.0-3.i386.rpm"
				elif [ $kk -eq 7 ]; then
				    nameall="vztmpl-fedora-9-1.1-1.i386.rpm"
				fi
				fname=`ls`
				mv -f $fname $nameall > /dev/null 2>&1
			fi				
			#  If download successful lets create x86_64 template
			templname=`ls vztmpl-*` # gets file name downloaded
			#  Install it
			$RPM -U $templname
			if [ $? -eq 0 ]; then
				template_64
				echo "vztmpl-${distr[kk]}-${dver[kk]}-x86_64... created!"
			fi
			rm -f $templname
			
		fi
	else
		echo "vztmpl-${distr[kk]}-${dver[kk]}-x86_64 already installed... skipping"
	fi
	kk=`expr $kk + 1`
done
cd $olddir
rm -fR /tmp/templvz.$$
if [ $err_q -eq 0 ]; then
	echo " ** "
	echo " All templates installed!"
elif [ $err_q -eq ${#templOS[@]} ]; then
	echo " ** DOWNLOAD UNSUCCESSFUL!!"
	echo "Any template dowloaded."
	echo "Connection problem? Server down?"
elif [ $err_q -gt 0 ]; then
	echo " ** ATENTION:"
	echo " ** Some templates were not downloaded!"
fi



#  Now this workaround is not very nice, but... it works...

#  Move 64 bits rpmmodules from rpm-python package to vzrpm4x 32 bits directory
dirvzrpm43=/usr/share/vzpkgtools/vzrpm43/lib/python${pyver}/site-packages
dirvzrpm44=/usr/share/vzpkgtools/vzrpm44/lib/python${pyver}/site-packages

#  If python 2.2
if [ "$pyver" = "2.2" ]; then
	$CP -f ${dirpy}/rpmmodule.so $dirvzrpm43/
	if [ -f "${dirpy}/rpmdb/_rpmdb.so" ]; then
		$CP -f ${dirpy}/rpmdb/_rpmdb.so $dirvzrpm43/rpmdb/
	fi
#  If python 2.3
elif [ "$pyver" = "2.3" ]; then
	$CP -f ${dirpy}/rpmmodule.so $dirvzrpm43
	if [ -f ${dirpy}/rpmdb/_rpmdb.so ]; then
		$CP -f ${dirpy}/rpmdb/_rpmdb.so $dirvzrpm43/rpmdb/
	fi
#  If python 2.4	
elif [ "$pyver" = "2.4" ]; then
	$CP -f ${dirpy}/rpm/_rpmmodule.so $dirvzrpm44/rpm/
	if [ -f ${dirpy}/rpmdb/_rpmdb.so ];then
		$CP -f ${dirpy}/rpmdb/_rpmdb.so $dirvzrpm44/rpmdb/
	fi
fi

echo "vzrpm python is fixed for 64 bits..."

#  Everything is now installed.
#  Let's patch the vz utilities
#  according to the steps described in the wiki page

echo "Applying patches..."
#---------------------------------
#  Change /usr/share/vzpkg/cache-os
#---------------------------------
if [ -f /usr/share/vzpkg/cache-os ]; then

patch -r /dev/null -N -p0 <<'EOF'
--- /usr/share/vzpkg/cache-os		2005-10-27 12:16:12.000000000 +0100
+++ /usr/share/vzpkg/cache-os.new	2009-02-28 01:10:52.000000000 +0000
@@ -133,7 +133,7 @@
 	# Check if updates are available
 	# We use $YUM not vzyum here as latter requires VPS to be running
 	$YUM --installroot $VE_ROOT $YUM_CONF_FILE \
-		--vps=$VEID check-update
+		check-update
 	YUMEC=$?
 	if test $YUMEC -eq 0; then
 		log3 "No updates are available"
@@ -151,6 +151,7 @@
 	cp -f $MYINIT $VE_ROOT/sbin/init || \
 		abort "Unable to copy $MYINIT to VPS root ($VE_ROOT)"
 	mkdir $VE_ROOT/proc || abort "Can't create dir $VE_ROOT/proc"
+	mkdir -p $VE_ROOT/var/lib/yum/ || abort "Can't create /var/lib/yum"
 fi
 
 
@@ -182,7 +183,7 @@
 XX_HOME=$HOME
 export HOME=$TDIR/config
 
-YUM_CMD="--installroot=$VE_ROOT --vps=$VEID $YUM_CONF_FILE -y $YUM_CMD"
+YUM_CMD="--installroot=$VE_ROOT $YUM_CONF_FILE -y $YUM_CMD"
 # -d $DEBUG_LEVEL
 log4 "Running $YUM $YUM_CMD"
 # FIXME1: We use $YUM not vzyum because latter requires OSTEMPLATE to be set.
EOF

fi        

#----------------------------------
#  Change /usr/share/vzpkg/functions
#----------------------------------
if [ -f /usr/share/vzpkg/functions ]; then

patch -r /dev/null -N -p0 << 'EOF1'
--- /usr/share/vzpkg/functions		2005-10-27 12:16:12.000000000 +0100
+++ /usr/share/vzpkg/functions.new	2009-03-04 21:29:48.000000000 +0000
@@ -17,9 +17,9 @@
 VZLOCKDIR=/vz/lock
 VECFGDIR=/etc/sysconfig/vz-scripts/
 VZCFG=/etc/sysconfig/vz
-VZLIB_SCRIPTDIR=/usr/lib/vzctl/scripts
-YUM=/usr/share/vzyum/bin/yum
-ARCHES="x86 i386 x86_64 ia64"
+VZLIB_SCRIPTDIR=/usr/lib64/vzctl/scripts
+YUM=`which yum`
+ARCHES="i386 x86_64 ia64 x86"
 
 # Handy functions
 
@@ -108,7 +108,7 @@
 	export VEID
 	export VZCTL
 	set +u
-	export RPM=`get_rpm $tdir`
+	export RPM=`which rpm`
 	log4 Calling script $script
 	# Run script
 	$script
@@ -447,7 +447,7 @@
 	done
 	
 	if ! test -z "$files"; then
-		rpm=`get_rpm $tdir`
+		rpm=`which rpm`
 		log4 "Importing RPM GPG keys: $files"
 		$rpm --root $VE_ROOT --import $files
 	fi
EOF1
fi  

#----------------------
#  Change /usr/bin/vzyum
#----------------------
if [ -f /usr/bin/vzyum ]; then

patch -r /dev/null -N -p0 << 'EOF2'
--- /usr/bin/vzyum	2005-10-27 12:16:12.000000000 +0100
+++ /usr/bin/vzyum.new	2008-02-26 12:42:34.000000000 +0000
@@ -48,9 +48,14 @@
 TDIR=$5
 check_ost_exists $OSNAME $OSVER $OSSET $OSARCH || exit 1
 YUM_ARGS=`yum_conf $TDIR`
-YUM_ARGS="$YUM_ARGS --installroot $VE_ROOT --vps=$VEID"
+YUM_ARGS="$YUM_ARGS --installroot $VE_ROOT"
 PYTHONPATH=`get_rpm_pythonhome $TDIR`
 export PYTHONPATH
 log4 PYTHONPATH=$PYTHONPATH
 log3 exec $YUM $YUM_ARGS $USER_ARGS
-exec $YUM $YUM_ARGS $USER_ARGS
+#exec $YUM $YUM_ARGS $USER_ARGS
+TMPVZY=/tmp/tmpvzy.$$
+echo $YUM $YUM_ARGS $USER_ARGS > $TMPVZY
+sh $TMPVZY
+exec rm -f $TMPVZY
+
EOF2
fi

#----------------------
#  Change /usr/bin/vzrpm
#----------------------
if [ -f /usr/bin/vzrpm ]; then

patch -r /dev/null -N -p0 << 'EOF3'
--- /usr/bin/vzrpm       2005-10-27 12:16:12.000000000 +0100
+++ /usr/bin/vzrpm.new   2007-04-05 01:43:10.000000000 +0100
@@ -37,7 +37,7 @@
 echo $STATUS | grep -qw "exist" || abort "VPS $VEID not exist!"
 echo $STATUS | grep -qw "running" || abort "VPS $VEID not running; " \
 	"you should start it first"
-RPM_ARGS="--root $VE_ROOT --veid $VEID"
+RPM_ARGS="--root $VE_ROOT"
 # Find out which RPM binary to use
 get_ve_os_template $VEID || abort "Can't get OSTEMPLATE for VPS $VEID"
 TEMPLATE=`get_vz_var TEMPLATE`
@@ -49,7 +49,7 @@
 OSARCH=$4
 TDIR=$5
 check_ost_exists $OSNAME $OSVER $OSSET $OSARCH || exit 1
-RPM=`get_rpm $TDIR`
+RPM=`which rpm`
 # Run it
 log3 exec $RPM $RPM_ARGS $USER_ARGS
 exec $RPM $RPM_ARGS $USER_ARGS
EOF3

fi

#-------------------------------------
#  Patch the centos-5 metadata cache-os
#  according to what contributor ft.linux said in
#  http://forum.openvz.org/index.php?t=msg&goto=32657&&srch=vztmpl-centos-5#msg_32840
#-------------------------------------

if [ -f /vz/template/centos/5/x86_64/config/install-post ]; then
patch -r /dev/null -N -p0 << 'EOF4'
--- /vz/template/centos/5/x86_64/config/install-post		2007-09-20 18:59:06.000000000 +0100
+++ /vz/template/centos/5/x86_64/config/install-post.new	2009-02-28 01:26:16.000000000 +0000
@@ -35,10 +35,10 @@
 $VZCTL exec2 $VEID sed -i -e '/getty/d' /etc/inittab
 
 # Disable klogd
-$VZCTL exec2 $VEID \
-	"sed -i -e 's/daemon\\ klogd/passed\\ klogd\\ skipped/' \
-		-e 's/killproc\\ klogd/passed\\ klogd\\ skipped/' \
-			/etc/init.d/syslog"
+#$VZCTL exec2 $VEID \
+#	"sed -i -e 's/daemon\\ klogd/passed\\ klogd\\ skipped/' \
+#		-e 's/killproc\\ klogd/passed\\ klogd\\ skipped/' \
+#			/etc/init.d/syslog"
 # FIXME: fix '/etc/init.d/syslog status' to return 0
 # even if klogd is not running
 
@@ -55,7 +55,7 @@
 # Disable fsync() in syslog
 $VZCTL exec2 $VEID \
 	'sed -i -e s@\\\([[:space:]]\\\)\\\(/var/log/\\\)@\\\1-\\\2@' \
-		/etc/syslog.conf
+		/etc/rsyslog.conf
 
 # Disable X11Forwarding by default
 $VZCTL exec2 $VEID \
EOF4

# copy the same file to i386
$CP -f /vz/template/centos/5/x86_64/config/install-post /vz/template/centos/5/i386/config/install-post
fi


echo
echo "END INSTALL!"

