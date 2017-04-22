#!/bin/sh
##############################################
#this scripts is create by guan at 20170325
##############################################
#set env
export PATH=$PATH:/bin:/sbin:/usr/sbin
export LANG="zh_CN.GB18030"

#Require root to run this scripts
if [[ "$(whoami)" != "root" ]];then
echo "Please run this scripts as root." >&2
exit1
fi

#define cmd var
SERVIVE=`which service`
CHKCONFIG=`which chkconfig`

#Source function library
. /etc/init.d/functions	

#Config Yum CentOS-Base.repo
ConfigYum(){
	echo "Config Yum CenOS-Base.repo."
	cd /etc/yum.repos.d/
	\cp CentOS-Base.repo CentOS-Base.repo.ori.$(date +%F)
	ping -c 1 baidu.com >/dev/null
	[ ! $? -eq 0 ] && echo $"Networking no configure - exiting" && exit 1
	wget --quiet -o /dev/null http://mirrors.aliyun.com/repo/Centos-6.repo
	\cp Centos-6.repo CentOS-Base.repo

}
#Change character GB18030
initI18n(){
	echo "#set LANG="zh_cn.gb18030""
	\cp /etc/sysconfig/i18n /etc/sysconfig/i18n.$(date +%F)
	sed -i 's#LANG="en_US.UTF-8"#LANG="zh_CN.GB18030"#' /etc/sysconfig/i18n
	source /etc/sysconfig/i18n
	grep LANG /etc/sysconfig/i18n
	sleep 1

}
#Install init Packages
installTool(){
	echo "sysstat ntp net-snmp lrzsz rsync telnet"
	yum -y install sysstat ntp net-snmp lrzsz rsync telnet net-tools >/dev/null 2>&1

}
#Close Selinux and Iptables 
initFirewall(){
	echo "Close Selinux and Iptables."
	\cp /etc/selinux/config /etc/selinux/config.`date +"%Y-%m-%d_%H:%M:%S"`
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	setenforce 0
	grep SELINUX=disabled /etc/selinux/config
	echo "Close selinux is OK and iptables is OK"
	sleep 1

}

#init Auto Startup Service
initService(){
	echo "Close Nouseful Service"
	export LANG="en_US.UTF-8"
	for guan in `chkconfig --list|grep 3:on|awk '{print $1}'`;do chkconfig --level 3 $guan off;done
	for guan in crond network rsyslog sshd ;do chkconfig --level 3 $guan on;done
	export LANG="zh_CN.GB18030"
	echo "Close Nouseful Service is OK"
	sleep 1

}
#initSsh 
initSsh(){
	echo "-------sshconfig--------"
	\cp /etc/ssh/sshd_config /etc/ssh/sshd_config.`date +"%Y-%m-%d_%H:%M:%S"`
	sed -i 's/#Port 22/Port 31111/' /etc/ssh/sshd_config
	sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
	sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
	sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
	egrep "31111|RootLogin|EmptyPass|UseDNS" /etc/ssh/sshd_config
	/etc/init.d/sshd reload && action $"--sshConfig--" /bin/true ||action $"--sshConfig--" /bin/false
	
}
#AddSaUser
AddSaUser(){
	echo "--add system user for all students--"
	datetmp=`date +"%Y-%m-%d_%H:%M:%S"`
	\cp /etc/sudoers /etc/sudoers.${datetmp}
	saUserArr=(su1 su2 su3)
	groupadd -g 901 sa
	for ((i=0;i<${#saUserArr[@]};i++))
do
	useradd -g sa -u 90${i} ${saUserArr[$i]}
	echo "${saUserArr[$i]}666"|passwd ${saUserArr[$i]} --stdin

	[ `grep "\%sa" /etc/sudoers|grep -v grep |wc -l` -ne 1 ] && \
	echo " %sa	ALL=(ALL)	NOPASSWD: ALL" >>/etc/sudoers
done
	/usr/sbin/visudo -c 
	[ $? -ne 0 ] && /bin/cp /etc/sudoers.${datetmp} /etc/sudoers && echo $"Sudoers not configured - exiting" && exit 1
	action $"add system user for all students is OK " /bin/true
	sleep 1
	
}
#syncSystemtime
syncSystemtime(){
	echo "--syncSystemTime--"
        file=/var/spool/cron/root
        if [ ! -f "$file" ];then
        touch "$file"
        fi
        if [ `grep time.nist.gov /var/spool/cron/root |grep -v grep |wc -l` -eq 0 ];then
        echo '*/5 * * * * /usr/sbin/ntpdate time.nist.gov >/dev/null 2>&1' >>/var/spool/cron/root
        fi
}
#set ulimit
openFiles(){
	echo "--set ulimit 65535--"
	\cp /etc/security/limits.conf /etc/security/limits.conf.`date +"%Y-%m-%d_%H:%M:%S"`
	sed -i '/# End of file/i\*\t\t-\tnofile\t\t65535' /etc/security/limits.conf
	ulimit -HSn 65535
	echo "ulimit -HSn 65535" >>/etc/rc.loadl
	echo "set ulimit is OK"
	sleep 1

}
#optimizationKernel
optimizationKernel(){
	echo "--optimizationKernel start--"
	 \cp /etc/sysctl.conf /etc/sysctl.conf.`date +"%Y-%m-%d_%H:%M:%S"`
	cat>>/etc/sysctl.conf <<EOF
	net.ipv4.tcp_timestamps = 0
	net.ipv4.tcp_synack_retries = 2
	net.ipv4.tcp_syn_retries = 2
	net.ipv4.tcp_mem = 94500000 915000000 927000000
	net.ipv4.tcp_max_orphans = 3276800
	net.core.wmem_default = 8388608
	net.core.rmem_default = 8388608
	net.core.rmem_max = 16777216
	net.core.wmem_max = 16777216
	net.ipv4.tcp_rmem = 4096 87380 16777216
	net.ipv4.tcp_rmem = 4096 65536 16777216
	net.core.netdev_max_backlog = 32768
	net.core.somaxconn = 32768
	net.ipv4.tcp_syncookies = 1
	net.ipv4.tcp_tw_reuse = 1
	net.ipv4.tcp_tw_recycle = 1
	net.ipv4.tcp_fin_timeout = 1
	net.ipv4.tcp_keepalive_time = 1200
	net.ipv4.tcp_max_syn_backlog = 65536
	net.ipv4.ip_local_port_range = 1024  65535
EOF
/sbin/sysctl -p && action $"optimizationKernel: " /bin/true||action $"optimizationKernel: " /bin/false  

}
echo "after 3s start init....."
sleep 3
ConfigYum
initI18n
installTool
initFirewall
initService
#initSsh
AddSaUser
syncSystemtime
openFiles
optimizationKernel

