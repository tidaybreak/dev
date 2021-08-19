source ~/.bash_profile
temp_path=$(dirname "$0")
cd $temp_path
real_path=$(pwd)
cd $real_path


host=$1
port=$2
command=$3

echo "host: $name $host"

scp -P $port -r centos7.sh $host:/root/

ssh -p $port $host "nohup /bin/sh /root/centos7.sh $command"

