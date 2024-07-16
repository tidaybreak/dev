# 物理机

* init
```
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
hostnamectl --static set-hostname 11-11-0-1

#base
yum -y install epel-release 
yum -y update
yum -y install vim sudo wget which net-tools bzip2 openssh-server openssh-clients telnet unzip dstat mysql lrzsz screen
yum -y install libtool gcc gcc-c++ make java-1.8.0-openjdk*
yum -y install net-tools
yum -y install gcc gcc-c++ wget telnet traceroute dstat -y

# X11连接
#解决The remote SSH server rejected X11 forwarding request
yum -y install xorg-x11-xauth
# vi /etc/ssh/sshd_config
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes
AddressFamily inet 


sed -i 's/<service name="ssh"\/>/<port protocol="tcp" port="2727"\/>/' /etc/firewalld/zones/public.xml
sed -i 's/#Port 22/Port 2727/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
systemctl restart firewalld

#开机启动加权限
chmod +x /etc/rc.d/rc.local

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
yum -y install ntp ntpdate
ntpdate cn.pool.ntp.org
hwclock --systohc
```

* 桥接
```
yum install bridge-utils
systemctl stop NetworkManager
systemctl disable NetworkManager

[root@localhost network-scripts]# cat ifcfg-em2 
NM_CONTROLLED=no
TYPE=Ethernet
NAME=em2
DEVICE=em2
ONBOOT=yes
BOOTPROTO=static
BRIDGE=br0
[root@localhost network-scripts]# cat ifcfg-br0 
DEVICE=br0
ONBOOT=yes
BOOTPROTO=static
TYPE=Bridge
IPADDR0=10.10.10.3
PREFIX0=16

ifup em2
#ping的通口不通
iptables -I FORWARD -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
#访问外网
iptables -t nat -A POSTROUTING -s 11.11.0.0/16 -j MASQUERADE

```

* kvm
```
yum install -y qemu-kvm qemu-img virt-manager libvirt libvirt-python python-virtinstlibvirt-client virt-install virt-viewer
systemctl start libvirtd
systemctl enable libvirtd

virsh define /home/data/libvirt/qemu/demo.xml
virt-clone -o demo -n vm1 -f /home/data/libvirt/images/vm1.qcow2
virsh autostart vm1
virsh start vm1
virsh console vm1

#解决kvm虚机不支持virsh console连接的问题
grubby --update-kernel=ALL --args="console=ttyS0"
reboot

#demo yum 
yum -y install net-tools gcc gcc-c++ wget telnet traceroute dstat lrzsz bzip2 ntpdate

改kvm密码：
yum -y update
yum -y install libguestfs-tools
 yum install libsoup
virsh dumpxml vm1|grep mac
virsh shutdown vm1
virt-edit vm1 /etc/shadow  #root:$6$X.nsrC7K$h1VxCjLktjOpP7P3xbBkkfKujPAjSv15ulSM..fksQchICfq.lwyrIFZvFQ/ByQxr/2yAn/Ynsz7TFVbgXXlQ0:17799:0:99999:7:::
#修改后密码2018FqQwEk5v@ofidc

改磁盘大小(只能加)
# 查询磁盘信息
qemu-img info /home/data/iso/sys.qcow2
# 增加50G空间
qemu-img resize /home/data/iso/sys.qcow2 +50G
# 准备使用virt-resize调整分区空间，而virt-resize不能原地扩容，需要制作一个备份
cp  /home/data/iso/sys.qcow2  /home/data/iso/sys-orig.qcow2
# 扩容分区/dev/sda1，这里可以扩容该磁盘的特定分区，最好确认需要扩容的挂载点所在分区
# 可以使用后面的验证分区大小命令确认需要扩容的分区
virt-resize --expand /dev/sda1  /home/data/iso/sys-orig.qcow2  /home/data/iso/sys.qcow2 
# 查看分区信息
qemu-img info /home/data/iso/sys.qcow2
# 验证分区大小
virt-filesystems --long -h --all -a /home/data/iso/sys.qcow2
5.虚拟机里面扩展/root所在的lv，增加50G
lvextend -L +50G/dev/mapper/centos-root
6.虚拟机里面扩展/root文件系统
xfs_growfs/dev/mapper/centos-root


挂新盘
 qemu-img create -f raw 11.11.10.1_50disk.img 50G
virsh attach-disk --domain 11.11.10.1 --source  /home/data/libvirt/images/11.11.10.1_50disk.img --target vdb --targetbus virtio --driver qemu --subdriver raw --sourcetype file --cache none --persistent
#卸载
virsh detach-disk 11.11.10.1 vdb --persistent
```

# K8s

* 集群安装(K8S_BIN_VER=v1.16.2)
```
#easzup-2.1.0
https://github.com/easzlab/kubeasz
加master:
ansible-playbook tools/03.addmaster.yml -e NODE_TO_ADD=11.11.30.1
加node:
ansible-playbook tools/02.addnode.yml -e NODE_TO_ADD=11.11.30.2
不加入调度:
kubectl uncordon 11.11.10.1



```

* deploy-tool必要相关
```
etcd 要开启http调用
	vim /etc/systemd/system/etcd.service
		--listen-client-urls=https://11.11.10.1:2379,http://11.11.10.1:2379,http://127.0.0.1:2379 \
kubeapi 开启httpbase
	vi /etc/systemd/system/kube-apiserver.service
		--basic-auth-file=/etc/kubernetes/auth.csv \
1.harhor要认证，deploy-tool 要加/root/.docker/config.json才能push成功
/etc/docker/daemon.json
	"hosts": ["tcp://0.0.0.0:4379","unix:///var/run/docker.sock"],
4.使用etcd3
	pip install --upgrade setuptools
	pip install etcd3-py
	
#远程调用
kubectl create clusterrolebinding root-cluster-admin-binding --clusterrole=cluster-admin --user=admin
kubectl -s https://11.11.10.1:6443 --insecure-skip-tls-verify=true --username=admin --password=mWMrzqHk3kqapAfV --namespace=default get nodes

```

* ceph安装(release-1.1.7)
```
https://blog.csdn.net/aixiaoyang168/article/details/86215080
https://blog.csdn.net/aixiaoyang168/article/details/86467931
http://www.yangguanjun.com/2018/12/22/rook-ceph-practice-part1/
https://hansedong.github.io/2018/12/18/11/

1.k8s/ceph/rook-1.1.7
2.k8s/ceph/filesystem.yaml
3.k8s/ceph/cephfs-provisioner

yum install nfs-utils -y
mount -t ceph 10.68.201.103:6789,10.68.215.157:6789,10.68.87.46:6789:/ /data/test -o name=admin,secret='AQAJFcFd34t9HBAAi2Gs7+ZMi6achSsWXnFW2w=='

加减节点 rook-1.1.7/cluster/examples/kubernetes/ceph/cluster.yaml:nodes 后apply  正常过一会儿会生效

1.虚拟机要raw磁盘
2.deploy报错：mount: wrong fs type, bad option, bad superblock on    
    yum -y install ceph-common
    不要装ceph-fuse  用mount  ceph-fuse有内存泄露被杀问题
    #yum -y install ceph-fuse
    ceph-fuse 可能不支持--client-quota sc不加要client-quota
3.错误：CephFS Provisioner Input/Output Error 或 
        ok, i just add -disable-ceph-namespace-isolation=true in the deployment, Input/output error just gone
    - args:
    - '-id=cephfs-provisioner-1'
    - '-disable-ceph-namespace-isolation=true'
    command:
    - /usr/local/bin/cephfs-provisioner

4. 错误：failed to get Plugin from volumeSpec for volume  err=no volume plugin matched
   要用这个 rook-1.1.7/cluster/examples/kubernetes/ceph/csi/rbd/storageclass.yaml 
   这个报错 rook-1.1.7/cluster/examples/kubernetes/ceph/flex/storageclass.yaml
   
5. ceph故障 1 mds daemon damaged
	http://askceph.com/article/5
	ceph mds repaired 0
	
6. cephfs元数据池故障的恢复     	https://ceph.io/planet/cephfs%E5%85%83%E6%95%B0%E6%8D%AE%E6%B1%A0%E6%95%85%E9%9A%9C%E7%9A%84%E6%81%A2%E5%A4%8D/

7. too few PGs per OSD (24 < min 30)
  ceph osd pool ls 要以下东西
  	cephfs-metadata
	cephfs-data0
	replicapool
	my-store.rgw.control
	my-store.rgw.meta
	my-store.rgw.log
	my-store.rgw.buckets.index
	my-store.rgw.buckets.non-ec
	.rgw.root
	my-store.rgw.buckets.data


8. 1 pools have many more objects per pg than average
   适当增加pg_num pgp_num
   https://blog.csdn.net/ygtlovezf/article/details/60778091
   ceph osd pool set cephfs_data pg_num 40
   ceph osd pool set cephfs_data pgp_num 40

```

* helm
```
https://get.helm.sh/helm-v3.0.0-rc.2-linux-amd64.tar.gz
```

* harbor
```
https://github.com/goharbor/harbor-helm/archive/v1.2.1.tar.gz
https://www.qikqiak.com/post/harbor-quick-install/
创建pvc
kubectl create namespace product
kubectl config set-context harbor --namespace=product
helm install -name harbor -f values.yaml . --namespace product
helm delete harbor

不用块存储可能会有权限问题，改成777

证书两种方案：
1.添加配置，文件/etc/docker/daemon.json
{
  "insecure-registries" : ["harbor.xxx.com"]
}
#重启docker

2.我们将使用到的ca.crt文件复制到/etc/docker/certs.d/registry.qikqiak.com目录下面，如果该目录不存在，则创建它。ca.crt 这个证书文件我们可以通过 Ingress 中使用的 Secret 资源对象来提供：
kubectl get secret harbor-harbor-ingress -n kube-ops -o yaml
其中 data 区域中 ca.crt 对应的值就是我们需要证书，不过需要注意还需要做一个 base64 的解码，这样证书配置上以后就可以正常访问了。


#登录
docker login -u=admin -p=Harbor12345 docker.li-rui.top
docker tag rook/ceph:v1.1.4 harbor.ofidc.com/library/rook/ceph:v1.1.4
docker push  harbor.ofidc.com/library/rook/ceph:v1.1.4
#登出
docker logout docker.li-rui.top
```

* gitlab
```
https://github.com/easzlab/kubeasz/blob/master/docs/guide/gitlab/readme.md
```


* 修改内存大小

```
kubectl get po {podname} -o yaml|grep resources -C 8
kubectl describe limits --all-namespaces
kubectl edit limits {limits}
kubectl get po {podname} -o yaml|grep resources -C 8
```

*保存对容器修改(可能无效  如对deploy-tool 会卡在CrashLoopBackOff)
```
#不能直接docker run, 要去容器所在的节点commit
#docker run -ti --rm registry.ofidc.com/deploy-tool:lufeng-dev-201909230000 /bin/bash
docker commit -a "ti" -m "why" 08a04f7c6114 registry.ofidc.com/deploy-tool:lufeng-dev-201909230000
docker push registry.ofidc.com/deploy-tool:lufeng-dev-201909230000


如果出现“No repository”的提示，很可能是repositories目录下的owner和gitlab的不匹配。
chown -R user:user repositories
gitlab-rake cache:clear RAILS_ENV=production
```


* 更新deploy-tool服务
```
cd /wls/deploy/deploy-tool/
git pull origin lufeng-dev
bash build.sh
docker build -t registry.ofidc.com/deploy-tool:lufeng-dev-201809230000 .
docker push registry.ofidc.com/deploy-tool:lufeng-dev-201809230000
kubectl set image deployment/deploy-tool deploy-tool=registry.ofidc.com/deploy-tool:lufeng-dev-201809230000
kubectl create -f deploy-tool-pvc.yaml
kubectl replace -f deploy-tool-deploy.yaml
```

* 更新gitlab服务
```
kubectl get deployment
kubectl get deploy gitlab-postgresql -o yaml > gitlab-postgresql-deploy.yaml
kubectl create -f gitlab-postgresql-deploy.yaml
kubectl delete deployment gitlab-postgresql2
kubectl delete po gitlab-postgresql-3707565690-1pvph --grace-period=0 --force
kubectl edit deployment gitlab-postgresql2
kubectl replace -f gitlab-postgresql-deploy.yaml
```

* pv pvc
```
kubectl  get pv
kubectl  get pvc
kubectl  get pv pvc-8667abd0-0300-11e7-b49d-525400f7fe5e -o yaml       #/volumes/kubernetes/kubernetes-dynamic-pvc-866c008d-0300-11e7-92e4-0242ac104a08

```


* Endpoints
```
kubectl get endpoints --all-namespaces|grep 3306
kubectl create -f endpoints.yaml

# endpoints.yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: mysql-cacti
  namespace: product
subsets:
- addresses:
  - ip: 10.10.20.32
  ports:
    - port: 3306
    
kubectl create -f svc.yaml
# svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-cacti
spec:
  ports:
    - port: 3306
      protocol: TCP
      targetPort: 3306    
```




```
yum install -y bridge-utils
systemctl stop NetworkManager
systemctl disable NetworkManager

iptables -I FORWARD -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -s 11.11.0.0/16 -j MASQUERADE

ifup em2
ifup br0


*/10 * * * * /usr/sbin/ntpdate cn.pool.ntp.org

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
sysctl -p
\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
yum update
yum -y install xorg-x11-xauth
yum install -y ntpdate
yum install -y qemu-kvm qemu-img virt-manager libvirt libvirt-python python-virtinstlibvirt-client virt-install virt-viewer
systemctl start libvirtd
systemctl enable libvirtd
ntpdate cn.pool.ntp.org
hwclock --systohc
chmod +x /etc/rc.d/rc.local
systemctl restart sshd


parted /dev/sdb
mkfs.ext4 /dev/sdb1
mkdir /data
mount /dev/sdb1 /data
vi /etc/fstab	
	/dev/sdb1 /data	ext4 defaults 0 0

	
s=121.46.133.162
scp -P 62738 /etc/sysconfig/network-scripts/ifcfg-em2 $s:/etc/sysconfig/network-scripts/
scp -P 62738 /etc/sysconfig/network-scripts/ifcfg-br0 $s:/etc/sysconfig/network-scripts/
scp -P 62738 /etc/sysctl.conf $s:/etc/
scp -P 62738 /etc/rc.local $s:/etc/

yum install -y https://www.percona.com/redir/downloads/percona-release/redhat/0.0-1/percona-release-0.0-1.x86_64.rpm
yum install -y sysbench


grep "[0-9]" /sys/devices/system/edac/mc/mc*/csrow*/ch*_ce_count
dmidecode -t memory |grep 'Locator: DIMM'

yum install -y libsysfs edac-utils
edac-util -v

```
