#!/bin/bash
#用于CentOS6.6最小化安装后的系统优化

#ssh服务配置优化（脚本运行前请配置至少一个具有sudo权限的用户）
sed -i 's@#PermitRootLogin yes@PermitRootLogin no@' /etc/ssh/sshd_config
sed -i 's@#PermitEmptyPasswords no@PermitEmptyPasswords no@' /etc/ssh/sshd_config
sed -i 's@#UseDNS yes yes@UseDNS no@' /etc/ssh/sshd_config
service sshd restart

#系统基础升级
cd /etc/yum.repos.d/
wget http://mirrors.163.com/.help/CentOS6-Base-163.repo
mv CentOS-Base.repo CentOS-Base.repo.bak
mv CentOS6-Base-163.repo CentOS6-Base.repo
yum clean all
yum makecache
yum update

#添加epel外部yum扩展源
cd /usr/local/src
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -ivh epel-release-6-8.noarch.rpm

#安装gcc基础库文件及sysstat工具
yum -y install gcc gcc-c++ vim-enhanced unzip unrar sysstat

#配置ntpdate自动对时
yum -y install ntp
echo "01 */12 * * * /usr/sbin/ntpdate ntp.api.bz  >> /dev/null 2>&1" >> /etc/crontab
ntpdate ntp.api.bz
service crond restart

#配置ulimit值
ulimit -SHn 65534
echo "ulimit -SHn 65534" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*		soft	nofile		65534
*		hard	nofile		65534
EOF

#基础系统内核优化
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384
EOF
/sbin/sysctl -p

#禁用control-alt-delete组合键防止误操作
sed -i 's@ca::ctrlaltdel:/sbin/shutdown -t3 -r now@#ca::ctrlaltdel:/sbin/shutdown -t3 -r now@' /etc/inittab

#关闭selinux
sed -i 's@SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
#关闭防火墙（不一定要做）
service iptables stop
chkconfig iptables off

禁用IPV6地址，模块和防火墙
echo "install  ipv6 /bin/true" > /etc/modprobe.d/disable-ipv6.conf
echo "IPV6INIT=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 #if the host use eth0
chkconfig ip6tables off

#vim相关
cat >> /root/.vimrc << EOF
set number
set ruler
set nohlsearch
set shiftwidth=2
set tabstop=4
set expandtab
set cindent
set autoindent
set mouse=v
syntax on
EOF

#开机自启动只保留四个服务，crond|network|rsyslog|sshd
for i in `chkconfig --list|grep 3:on|awk '{print $1'`;do chkconfig --level 3 $i off;done
for CURSRV in crond rsyslog sshd network;do chkconfig --level 3 $CURSRV on;done




