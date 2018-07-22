#!/bin/bash -x
#
TYPE=centos
USER=centos
NUMINSTANCES=5
HOSTPREFIX='hgalante-'
FIELDPEM='field.pem'
START=1

n=$START
while [[ $n -lt $NUMINSTANCES ]]; do
	echo $hostprefix$n
	ssh -t -i $FIELDPEM $USER@$HOSTPREFIX$n.field.hortonworks.com 'sudo -n cp /home/$USER/.ssh/authorized_keys /root/.ssh/'
	scp -i $FIELDPEM $FIELDPEM root@$HOSTPREFIX$n.field.hortonworks.com:/root/.ssh/id_rsa
	ssh -t -i $FIELDPEM root@$HOSTPREFIX$n.field.hortonworks.com "echo never > /sys/kernel/mm/transparent_hugepage/enabled; echo never > /sys/kernel/mm/transparent_hugepage/defrag"
	let n++
done

if [[ "$TYPE" == "ubuntu" ]];
then
	n=$START
	while [ $n -lt $NUMINSTANCES ]; do
		echo $hostprefix$n
		scp -i $FIELDPEM $FIELDPEM rc.local root@$HOSTPREFIX$n.field.hortonworks.com:/etc/rc.local
		ssh -t -i $FIELDPEM root@$HOSTPREFIX$n.field.hortonworks.com "apt-get update; apt-get -q -y install zip unzip wget ntp; apt-get -fu install python; apt-get -f -q -y dist-upgrade"
		let n++
	done

ssh root@${HOSTPREFIX}0.field.hortonworks.com "wget -O /etc/apt/sources.list.d/ambari.list http://public-repo-1.hortonworks.com/ambari/ubuntu14/2.x/updates/2.6.2.2/ambari.list; apt-key adv --recv-keys --keyserver keyserver.ubuntu.com B9733A7A07513CAD; apt-get update"

elif [[ "$TYPE" == "centos" ]];
then
	n=$START
	while [ $n -lt $NUMINSTANCES ]; do
		echo $hostprefix$n
		scp -i $FIELDPEM centos_selinux_config root@$HOSTPREFIX$n.field.hortonworks.com:/etc/selinux/config
		scp -i $FIELDPEM centos_etc_profile root@$HOSTPREFIX$n.field.hortonworks.com:/etc/profile
		scp -i $FIELDPEM centos_rc_local root@$HOSTPREFIX$n.field.hortonworks.com:/etc/rc.d/rc.local

		ssh -t -i $FIELDPEM root@$HOSTPREFIX$n.field.hortonworks.com "/usr/bin/chmod +x /etc/rc.d/rc.local; yum install -y net-tools vim reposync curl wget unzip zip chkconfig tar openssh-clients ntp; systemctl enable ntpd; systemctl start ntpd; systemctl disable firewalld; service firewalld stop; setenforce 0"
		sleep 5
		ssh -t -i $FIELDPEM root@$HOSTPREFIX$n.field.hortonworks.com "sleep 5; /sbin/reboot"
		let n++
	done

#HDF repo
	ssh -t -i $FIELDPEM root@${HOSTPREFIX}$START.field.hortonworks.com "wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.6.2.2/ambari.repo -O /etc/yum.repos.d/ambari.repo"

fi

