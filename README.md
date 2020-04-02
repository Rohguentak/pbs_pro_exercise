# pbs_pro_exercise
vm으로 cluster 구성 후 pbs_pro 설치후 test하기
os: centos6.4
구성 #1: pbs-host 서버 1대, 계산 노드 2대
구성 #2: pbs-host 서버 2대, 계산 노드 1대 (failover 구성)
centos 서버 구축 및 ssh 접속 설정
------------------------------------------------------------------------------------------------------------------------------------
1. vagrant 사용해서 vm 3대 구성
   - vagrant up
   - vagrant ssh pbs-host //pbs-host에 접속

2. ssh를 이용하여 pbs-host에서 password없이 pbs-mom-1과 pbs-mom-2에 접속가능하게 함
   - ssh-keygen
   - ssh-copy-id 172.28.128.11 하거나 vi /etc/hosts에 172.28.128.11 pbs-mom-1을 추가한 뒤 ssh-copy-id pbs-mom-1 실행
   
nfs로 home directory 공유
------------------------------------------------------------------------------------------------------------------------------------
nfs-server 
----------
#yum install -y vim rpcbind nfs-utils nfs-utils-lib
#chkconfig --level 35 nfs on
#chkconfig --level 35 nfslock on
#chkconfig --level 35 rpcbind on      //서버가 다시시작되었을 때 자동으로 실행되게 설정

#sudo service rpcbind start
#sudo service nfslock start
#sudo service nfs start 

#rpcinfo -p localhost //실행되는지 확인

#vi /etc/exports
/home/vagrant 172.28.128.11(rw,no_root_squash,sync)    //nfs-client주소 추가

#sudo service nfs restart
#ssh pbs-mom-1               //nfs-client에 ssh로 접속

nfs-client
----------
#yum install -y nfs-utils nfs-utils-lib nfs-utils-lib-devel nfs4-acl-tools libgssglue-devel 
#mount -t nfs 172.28.128.10:/home/vagrant /home/vagrant 


------------------------------------------------------------------------------------------------------------------------------------

