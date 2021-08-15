function echo_file(){
FIND_FILE=$1
FIND_STR=$2
if [ `grep -F -c "$FIND_STR" $FIND_FILE` == '0' ];then
cat >>$FIND_FILE<<EOF
$2
EOF
fi
}

function exec_file(){
FIND_FILE=$1
FIND_STR=$2
if [ `grep -F -c "$FIND_STR" $FIND_FILE` == '0' ];then
echo `$3`
fi
}


#selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

#rc.local
chmod +x /etc/rc.d/rc.local

#crontab 
echo_file "/var/spool/cron/root" '0 0 * * * /usr/sbin/ntpdate cn.pool.ntp.org'

#bashrc
c=$(cat<<\EOF
export HISTSIZE=50000
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
export PS1="[\u@\h-`/sbin/ifconfig | sed -nr 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'|grep -v 172|grep -v 127|head -n1` \w]\$"
export PROMPT_COMMAND='{ msg=$(history 1 | { read x y; echo $y; });user=$(whoami); echo $(date "+%Y-%m-%d %H:%M:%S"):$user:`pwd`/:$msg ---- $(who am i); } >> /var/log/`hostname`.`whoami`.history-timestamp'
EOF
)
echo_file "/root/.bashrc" "$c"

#sshd_config
exec_file /etc/firewalld/zones/public.xml '62738' 'firewall-cmd --permanent --add-port=62738/tcp'
sed -i 's/#Port 22/Port 62738/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

#x11
yum -y install xorg-x11-xauth
sed -i 's/#X11DisplayOffset 10/X11DisplayOffset 10/' /etc/ssh/sshd_config
sed -i 's/#X11UseLocalhost yes/X11UseLocalhost yes/' /etc/ssh/sshd_config
sed -i 's/#X11Forwarding yes/X11Forwarding yes/' /etc/ssh/sshd_config
sed -i 's/#AddressFamily any/AddressFamily inet/' /etc/ssh/sshd_config

#time
timedatectl set-timezone Asia/Shanghai
\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
yum -y install ntp ntpdate
ntpdate cn.pool.ntp.org
hwclock --systohc

#docker
curl -fsSL get.docker.com -o get-docker.sh
sudo sh get-docker.sh --mirror Aliyun
sudo systemctl enable docker
sudo systemctl start docker
docker network create --subnet=172.18.0.0/16 mynet
docker network ls

exit

yum -y install epel-release 
yum -y update
