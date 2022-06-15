#不存在就写入文件
function echo_file(){
	FIND_FILE=$1
	FIND_STR=$2
	touch $FIND_FILE
	if [ -n "$3" ] ; then
    	FIND_STR=$3
	fi
	echo "config:$FIND_FILE find:$FIND_STR replace:$2"
	if [ `grep -F -c "$FIND_STR" $FIND_FILE` == '0' ];then
		cat >>$FIND_FILE<<EOF
$2
EOF
	fi
}

#config
function conf(){
	CONFIG_FILE=$1
	NAME=$2
	VALUE=$3
	touch $CONFIG_FILE
	if [ ! -n "$VALUE" ] ; then
		echo "config del:$CONFIG_FILE $NAME"
		sed -i "s/^$NAME/#$NAME/" $CONFIG_FILE
	else
		echo "config set:$CONFIG_FILE $NAME$VALUE"
		if [ `grep -c "^$NAME" $CONFIG_FILE` == '0' ];then
			cat >>$CONFIG_FILE<<EOF
$NAME$VALUE
EOF
		else
			#VALUE=`echo $VALUE | sed 's#\##\\##g'`
			sed -i "s#^$NAME.*#$NAME$VALUE#" $CONFIG_FILE
		fi
	fi
}
function conf_eq() {
	conf $1 "$2=" "$3"
}
function conf_sp() {
	conf $1 "$2 " "$3"
}

#执行
function exec_file(){
	FIND_FILE=$1
	FIND_STR=$3
	if [ "$FIND_STR" != "" ];then
		if [ `grep -F -c "$FIND_STR" $FIND_FILE` == '0' ];then
			echo `$2`
		fi
	else
		if [ ! -x "$FIND_FILE" ]; then
			echo `$2`
		fi
	fi
}


#selinux
conf_eq /etc/selinux/config SELINUX disabled
setenforce 0

#rc.local
chmod +x /etc/rc.d/rc.local

#crontab 
echo_file "/var/spool/cron/root" '0 0 * * * /usr/sbin/ntpdate cn.pool.ntp.org'

#/root/.vimrc
conf_eq /root/.vimrc 'set ts' '4'
conf_eq /root/.vimrc 'set sw' '4'

#bashrc
exec_file /usr/bin/xauth 'yum -y install vim'
conf_eq /root/.bashrc 'alias vi' "'vim'"
conf_eq /root/.bashrc HISTSIZE 50000
conf_eq /root/.bashrc HISTTIMEFORMAT '"%Y-%m-%d %H:%M:%S "'
v=$(cat<<\EOF
"[\\u@\\h-`/sbin/ifconfig | sed -nr 's/.*inet (addr:)?(([0-9]*\\.){3}[0-9]*).*/\\2/p'|grep -v 172|grep -v 127|head -n1` \\w]\\$"
EOF
)
conf_eq /root/.bashrc 'export PS1' "$v"
v=$(cat<<\EOF
'{ msg=$(history 1 | { read x y; echo $y; });user=$(whoami); echo $(date "+%Y-%m-%d %H:%M:%S"):$user:`pwd`/:$msg ---- $(who am i); } >> /var/log/`hostname`.`whoami`.history-timestamp'
EOF
)
conf_eq /root/.bashrc 'export PROMPT_COMMAND' "$v"
source /root/.bashrc

#ssh authorized
mkdir /root/.ssh
echo_file /root/.ssh/authorized_keys "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDdIKufN5U0d/tl3/UYQjkKcSmWJSR/38WzSgk0wjdd/gd95yIQ88r7p5P+EeFE4E2mbSXASHDfVak3LVqo27RMps9efrTt9DEGic8IRQ3BpEtJihrtmPRRXMzdWHM4vTMzAUrgxflkIYTTri6WpCb6TI9PpG/cGkiSF/Kcb+mYWw=="
echo_file /root/.ssh/authorized_keys "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA2nh8X/53vIzahycXuDgSwwbnuC8N8EABMs/yuzwufS7gpM2fZ4q3HcKDd8bLI7vnXbf2Tn52idDMeiLfhVHQ5YatXsyI/bR+1XVzCD8qAYWIlpnwIELF10i160k/ggc7pRDOMN4+jhkU/y0kxfzVoaj6iP5WKg7I/+9fe87kT53Ah25j/xaMkDSzlbXgonE+L+wAKZwFlrHVoWKz2BVc97tNFH+zS3z6fYb4C1lA2gKNe5C778axWlFgq3LiO0j0ZYmnxeOEKMPpUnS8wbh1aNgHRBz/TmZU5AORdENv17kDakCe/miad/VxasEF9E2LCBWPb5xpX42xUG79q2vN2w== rsa ti-pass"

#sshd_config
exec_file /etc/firewalld/zones/public.xml 'firewall-cmd --permanent --add-port=62738/tcp' '62738'
conf_sp /etc/ssh/sshd_config Port 62738
conf_sp /etc/ssh/sshd_config UseDNS no
conf_sp /etc/ssh/sshd_config PasswordAuthentication no

#x11
exec_file /usr/bin/xauth 'yum -y install xorg-x11-xauth'
conf_sp /etc/ssh/sshd_config X11DisplayOffset 10
conf_sp /etc/ssh/sshd_config X11UseLocalhost yes
conf_sp /etc/ssh/sshd_config X11Forwarding yes
conf_sp /etc/ssh/sshd_config AddressFamily inet

#sysctl
conf_eq /etc/sysctl.conf net.ipv4.ip_forward 1
conf_eq /etc/sysctl.conf net.ipv4.conf.all.rp_filter 0
conf_eq /etc/sysctl.conf fs.file-max 1000000
conf_eq /etc/sysctl.conf net.ipv4.tcp_tw_recycle 0
conf_eq /etc/sysctl.conf net.ipv4.tcp_tw_recycle 0
conf_eq /etc/sysctl.conf net.netfilter.nf_conntrack_max 1000000
conf_eq /etc/sysctl.conf net.nf_conntrack_max 1000000
sysctl -p

#security limits
conf_sp /etc/security/limits.conf 'root soft nofile' '1000000'
conf_sp /etc/security/limits.conf 'root hard nofile' '1000000'
conf_sp /etc/security/limits.conf '* soft nofile' '1000000'
conf_sp /etc/security/limits.conf '* hard nofile' '1000000'


#time
exec_file /usr/sbin/ntpdate 'yum -y install ntp ntpdate;ntpdate cn.pool.ntp.org;hwclock --systohc'
timedatectl set-timezone Asia/Shanghai
\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#yum
exec_file /usr/bin/git 'yum -y install git'


if [ "$1" = "update" ] ; then
	yum -y install epel-release 
	yum -y update
        yum -y net-tools wget unzip
fi

if [ "$1" = "proxy" ] ; then
	v=$(cat<<\EOF
export http_proxy=http://wengzt%40ofidc.com:ti@node2.tiham.com:1090
export https_proxy=http://wengzt%40ofidc.com:ti@node2.tiham.com:1090
export ftp_proxy=http://wengzt%40ofidc.com:ti@node2.tiham.com:1090
exec ${@:1}
EOF
)
	echo_file /usr/bin/proxy "$v"
	chmod 777 /usr/bin/proxy
fi

#docker
if [ "$1" = "docker" ] ; then
	curl -fsSL get.docker.com -o get-docker.sh
	sudo sh get-docker.sh --mirror Aliyun
	sudo systemctl enable docker
	sudo systemctl start docker
	docker network create --subnet=172.18.0.0/16 mynet
	docker network ls
fi
