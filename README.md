﻿# pbs_pro_exercise
vm으로 cluster 구성 후 pbspro 설치 및 test하기
------------------------------------------------------------------------------------------------------------------------------------
      -os: centos6.4

      -pbspro 버전: pbspro-18.1.4

      -구성 #1: pbs-host 서버 1대, 계산 노드 2대 , nfs 서버 1대

      -구성 #2: pbs-host 서버 2대, 계산 노드 1대 , nfs 서버 1대 (failover 구성)


   centos 서버 구축 및 ssh 접속 설정
   ------------------------------------------------------------------------------------------------------------------------------------
       1. vagrant 사용해서 vm 4대 구성
         - vagrant up
         - vagrant ssh pbs-nfs                       //pbs-host에 접속


      2. ssh를 이용하여 pbs-nfs에서 password없이 pbs components에 접속가능하게 함
         - ssh-keygen
         - ssh-copy-id 172.28.128.11 하거나 vi /etc/hosts에 172.28.128.11 pbs-host를 추가한 뒤 ssh-copy-id pbs-host 실행
   
   
   
   
   
   nfs로 home directory 공유
   ------------------------------------------------------------------------------------------------------------------------------------



   nfs-server 
   ----------
      #yum install -y vim rpcbind nfs-utils nfs-utils-lib

      #chkconfig --level 35 nfs on
      #chkconfig --level 35 nfslock on
      #chkconfig --level 35 rpcbind on                       //서버가 다시시작되었을 때 자동으로 실행되게 설정

      #sudo service rpcbind start
      #sudo service nfslock start
      #sudo service nfs start 

      #rpcinfo -p localhost                                  //실행되는지 확인

      #vi /etc/exports
      /home/vagrant 172.28.128.11(rw,no_root_squash,sync)    //nfs-client주소 추가
      #sudo service nfs restar



   nfs-client
   ----------
      #yum install -y nfs-utils nfs-utils-lib nfs-utils-lib-devel nfs4-acl-tools libgssglue-devel 
      #mkdir /data
      #mount -t nfs 172.28.128.10:/data /data                     //failover구성을 위해 PBS_HOME을 위한 디렉토리
      #mount -t nfs 172.28.128.10:/home/vagrant /home/vagrant     //공통파일 설치를 위한 마운트


   pbs설치 사전작업(failover구성시)
   ----------------
            nfs-server에서 수행
            #yum install -y postgresql-server          //nfs서버에 postgresql의 default 유저인 postgres를 생성하기 위함
            #wget https://github.com/PBSPro/pbspro/releases/download/v18.1.4/pbspro-18.1.4.tar.gz
         
   pbspro 설치(구성 #1: pbs-host 서버1대, 계산 노드 2대, nfs 서버 1대)
   ------------------------------------------------------------------------------------------------------------------------------------
   pbs-host
   --------

      #yum install -y gcc make rpm-build libtool hwloc-devel libX11-devel libXt-devel libedit-devel libical-devel ncurses-devel perl            postgresql-devel python-devel tcl-devel  tk-devel swig expat-devel openssl-devel libXext libXft wget postgresql-server

      #wget https://github.com/PBSPro/pbspro/releases/download/v18.1.4/pbspro-18.1.4.tar.gz           // /home/vagrant에 설치
      #tar -xpvf pbspro-18.1.4.tar.gz
      #cd pbspro-18.1.4

      #./autogen.sh                       //configure script와 Makefile들 생성
      #./configure                        //설치 환경 설정 ex)--prefix= 로 pbs_exec의 위치, --with-pbs-server-home= 으로 pbs_home의 위치 설정 가능
      #make
      #sudo make install                  // pbs컴파일 및 설치

      #sudo /opt/pbs/libexec/pbs_postinstall                //config 설정을 위해 post install 실행
      #sudo vi /etc/pbs.conf
            PBS_SERVER=pbs-host 
            PBS_START_SERVER=1        
            PBS_START_SCHED=1
            PBS_START_COMM=1
            PBS_START_MOM=0                                 // MOM은 계산노드에서 돌아가므로 0으로 설정
            PBS_EXEC=/opt/pbs  
            PBS_HOME=/var/spool/pbs
            PBS_CORE_LIMIT=unlimited
            PBS_SCP=/usr/bin/scp

      #sudo chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp                  //일반 유저도 pbs접근 가능하도록 설정
      #sudo /etc/init.d/pbs start                                                   //pbs 시작
      #sudo /etc/init.d/pbs status
            pbs_server is pid 32098
            pbs_sched is pid 31863
            pbs_comm is 31857




pbs-mom
-------
      #yum install -y gcc make rpm-build libtool hwloc-devel libX11-devel libXt-devel libedit-devel libical-devel ncurses-devel perl            postgresql-devel python-devel tcl-devel  tk-devel swig expat-devel openssl-devel libXext libXft wget
      #cd /home/vagrant/pbspro-18.1.4                       //nfs로 공유된 디렉토리

      #./autogen.sh
      #./configure
      #make
      #sudo make install                                    // pbs컴파일 및 설치
      #sudo /opt/pbs/libexec/pbs_postinstall                //config 설정을 위해 post install 실행

      #sudo vi /etc/pbs.conf
           PBS_SERVER=pbs-host                              //host서버의 hostname이어야함
           PBS_START_SERVER=0         
           PBS_START_SCHED=0
           PBS_START_COMM=0
           PBS_START_MOM=1                                  // MOM은 계산노드에서 돌아가므로 1으로 설정
           PBS_EXEC=/opt/pbs  
           PBS_HOME=/var/spool/pbs
           PBS_CORE_LIMIT=unlimited
           PBS_SCP=/usr/bin/scp
   
   
      #sudo chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
      #sudo /etc/init.d/pbs start
      #sudo /etc/init.d/pbs status
            pbs_mom is pid 21362                            //계산노드에선 pbs_mom만 실행




test
------------------------------------------------------------------------------------------------------------------------------------

      #pbsnodes -a                                          //노드 생성안되어있음
      #qstat -B                                             //서버확인
          Server             Max   Tot   Que   Run   Hld   Wat   Trn   Ext Status
          ---------------- ----- ----- ----- ----- ----- ----- ----- ----- -----------
          pbs-host             0     0     0     0     0     0     0     0 Active

      #qmgr
      Max open servers: 49
      Qmgr:p s                                              //서버와 queue 설정
            #Create queues and set their attributes.
            #
            #
            #Create and define queue workq
            #
            create queue workq
            #
            set queue workq queue_type = Execution
            set queue workq enabled = True
            set queue workq started = True
            #
            #Set server attributes.
            #
            set server scheduling = True
            set server default_queue = workq
            set server log_events = 511
            set server mail_from = adm
            set server query_other_jobs = True
            set server resources_default.ncpus = 1
            set server default_chunk.ncpus = 1
            set server scheduler_iteration = 600
            set server resv_enable = True
            set server node_fail_requeue = 310
            set serve max_array_size = 10000
            set server pbs_license_min = 0
            set server pbs_license_max = 2147483647
            set server pbs_license_linger_time = 31536000
            set server eligible_time_enable = False
            set server max_concurrent_provision = 5
      Qmgr: list node
           No Active Nodes, nothing done.
      Qmgr: create node pbs-mom-1
      Qmgr: active node pbs-mom-1
      Qmgr: exit

      #pbsnodes -a
            pbs-mom-1
            Mom = pbs-mom-1    
            Port = 15002    
            pbs_version = 18.1.4     
            ntype = PBS     
            state = free     
            pcpus = 1    
            resources_available.arch = linux    
            resources_available.host = pbs-mom-1    
            resources_available.mem = 603764kb    
            resources_available.ncpus = 1    
            resources_available.vnode = pbs-mom-1   
            resources_assigned.accelerator_memory = 0kb   
            resources_assigned.hbmem = 0kb  
            resources_assigned.mem = 0kb     
            resources_assigned.naccelerators = 0     
            resources_assigned.ncpus = 0   
            resources_assigned.vmem = 0kb     
            resv_enable = True    
            sharing = default_shared    
            last_state_change_time = Thu Apr  2 05:43:19 2020   
            last_used_time = Thu Apr  2 05:43:19 2020
     
      #echo "sleep 200" | qsub                               //root계정에서 job제출하면 안됨
            11.pbs-host                                      //job id
      #qstat -a
            pbs-host:
                                                                        Req'd  Req'd   Elap
            Job ID          Username Queue    Jobname    SessID NDS TSK Memory Time  S Time
            --------------- -------- -------- ---------- ------ --- --- ------ ----- - -----
            11.pbs-host     vagrant  workq    STDIN       18685   1   1    --    --  R 00:00

      #ssh pbs-mom-1
      #ps -ef | grep sleep

            vagrant  18707 18706  0 07:06 ?        00:00:00 sleep 200               //host에서 제출한 job이 
            vagrant  18734 18712  0 07:10 pts/0    00:00:00 grep sleep              //스케줄링 됨


   pbspro 설치(구성 #2: pbs-host 서버 2대, 계산 노드 1대, nfs 서버 1대)
   ------------------------------------------------------------------------------------------------------------------------------------
   pbs-host1
   ---------
            #yum install -y gcc make rpm-build libtool hwloc-devel libX11-devel libXt-devel libedit-devel libical-devel ncurses-devel perl postgresql-devel python-devel tcl-devel  tk-devel swig expat-devel openssl-devel libXext libXft wget postgresql-server rpmdevtools
            #rpmdev-setuptree
            #wget https://github.com/PBSPro/pbspro/releases/download/v18.1.4/pbspro-18.1.4.tar.gz
            #tar -xpvf pbspro-18.1.4.tar.gz
            #mv pbspor-18.1.4.tar.gz ~/rpmbuild/SOURCES
            #cd pbspro-18.1.4

            #./autogen.sh                       //configure script와 Makefile들 생성
            #./configure                        //설치 환경 설정 ex)--prefix= 로 pbs_exec의 위치, --with-pbs-server-home= 으로 pbs_home의  위치 설정 가능
            #make
            #cp pbspro.spec ~/rpmbuild/SPECS
            #cd ~/rpmbuild/SPECS
            #rpmbuild -ba pbspro.spec
            #rpm -Uvh ~/rpmbuild/RPMS/x86_64/pbspro-server-18.1.4-0.x86_64.rpm --nodeps
            #vi /etc/hosts
            172.28.128.20     pbs-host1   pbs-host1
            172.28.128.21     pbs-host2   pbs-host2
            172.28.128.22     pbs-mom     pbs-mom
            #vi /etc/pbs.conf
            PBS_EXEC=/opt/pbs
            PBS_SERVER=pbs-host1
            PBS_PRIMARY=pbs-host1
            PBS_SECONDARY=pbs-host2
            PBS_START_SERVER=1
            PBS_START_SCHED=1
            PBS_START_COMM=1
            PBS_START_MOM=0
            PBS_HOME=/data/pbs
            PBS_CORE_LIMIT=unlimited
            PBS_SCP=/usr/bin/scp
            #sudo chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
            #service pbs start
                        
   pbs-host2
   ---------
            #yum install -y gcc make rpm-build libtool hwloc-devel libX11-devel libXt-devel libedit-devel libical-devel ncurses-devel perl postgresql-devel python-devel tcl-devel  tk-devel swig expat-devel openssl-devel libXext libXft wget postgresql-server rpmdevtools
            #rpmdev-setuptree
            #wget https://github.com/PBSPro/pbspro/releases/download/v18.1.4/pbspro-18.1.4.tar.gz
            #tar -xpvf pbspro-18.1.4.tar.gz
            #mv pbspor-18.1.4.tar.gz ~/rpmbuild/SOURCES
            #cd pbspro-18.1.4

            #./autogen.sh                       //configure script와 Makefile들 생성
            #./configure                        //설치 환경 설정 ex)--prefix= 로 pbs_exec의 위치, --with-pbs-server-home= 으로 pbs_home의  위치 설정 가능
            #make
            #cp pbspro.spec ~/rpmbuild/SPECS
            #cd ~/rpmbuild/SPECS
            #rpmbuild -ba pbspro.spec
            #rpm -Uvh /root/rpmbuild/RPMS/x86_64/pbspro-server-18.1.4-0.x86_64.rpm --nodeps
            #vi /etc/hosts
            172.28.128.20     pbs-host1   pbs-host1
            172.28.128.21     pbs-host2   pbs-host2
            172.28.128.22     pbs-mom     pbs-mom
            #vi /etc/pbs.conf
            PBS_EXEC=/opt/pbs
            PBS_SERVER=pbs-host1
            PBS_PRIMARY=pbs-host1
            PBS_SECONDARY=pbs-host2
            PBS_START_SERVER=1
            PBS_START_SCHED=0                   //scheduler 실행 x
            PBS_START_COMM=1
            PBS_START_MOM=0
            PBS_HOME=/data/pbs
            PBS_CORE_LIMIT=unlimited
            PBS_SCP=/usr/bin/scp
            #sudo chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
            #service pbs start
            
   pbs-mom
   -------
            #yum install -y gcc make rpm-build libtool hwloc-devel libX11-devel libXt-devel libedit-devel libical-devel ncurses-devel perl postgresql-devel python-devel tcl-devel  tk-devel swig expat-devel openssl-devel libXext libXft wget rpmdevtools
            #rpmdev-setuptree
            #wget https://github.com/PBSPro/pbspro/releases/download/v18.1.4/pbspro-18.1.4.tar.gz
            #tar -xpvf pbspro-18.1.4.tar.gz
            #mv pbspor-18.1.4.tar.gz ~/rpmbuild/SOURCES
            #cd pbspro-18.1.4

            #./autogen.sh                       //configure script와 Makefile들 생성
            #./configure                        //설치 환경 설정 ex)--prefix= 로 pbs_exec의 위치, --with-pbs-server-home= 으로 pbs_home의  위치 설정 가능
            #make
            #cp pbspro.spec ~/rpmbuild/SPECS
            #cd ~/rpmbuild/SPECS
            #rpmbuild -ba pbspro.spec
            #rpm -Uvh /root/rpmbuild/RPMS/x86_64/pbspro-execution-18.1.4-0.x86_64.rpm --nodeps
            #vi /etc/hosts
            172.28.128.20     pbs-host1   pbs-host1
            172.28.128.21     pbs-host2   pbs-host2
            172.28.128.22     pbs-mom     pbs-mom
            #vi /etc/pbs.conf
            PBS_EXEC=/opt/pbs
            PBS_SERVER=pbs-host1
            PBS_PRIMARY=pbs-host1
            PBS_SECONDARY=pbs-host2
            PBS_START_SERVER=0
            PBS_START_SCHED=0                   
            PBS_START_COMM=0
            PBS_START_MOM=1                           //mom만 실행
            PBS_HOME=/data/pbs
            PBS_CORE_LIMIT=unlimited
            PBS_SCP=/usr/bin/scp
            #sudo chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
            #service pbs start
            
            
            
   test failover
   -------------
            # pbsnodes -a
            pbsnodes: Server has no node list
            # qstat -B
            Server             Max   Tot   Que   Run   Hld   Wat   Trn   Ext Status
            ---------------- ----- ----- ----- ----- ----- ----- ----- ----- -----------
            pbs-host1            0     0     0     0     0     0     0     0 Active
            # qmgr
            Max open servers: 49
            Qmgr: p s
            #
            # Create queues and set their attributes.
            #
            #
            # Create and define queue workq
            #
            create queue workq
            set queue workq queue_type = Execution
            set queue workq enabled = True
            set queue workq started = True
            #
            # Set server attributes.
            #
            set server scheduling = True
            set server default_queue = workq
            set server log_events = 511
            set server mail_from = adm
            set server query_other_jobs = True
            set server resources_default.ncpus = 1
            set server default_chunk.ncpus = 1
            set server scheduler_iteration = 600
            set server resv_enable = True
            set server node_fail_requeue = 310
            set server max_array_size = 10000
            set server pbs_license_min = 0
            set server pbs_license_max = 2147483647
            set server pbs_license_linger_time = 31536000
            set server eligible_time_enable = False
            set server max_concurrent_provision = 5
            
            #echo "sleep 200" | qsub                               //root계정에서 job제출하면 안됨
            11.pbs-host                                      //job id
            #qstat -a
            pbs-host:
                                                                        Req'd  Req'd   Elap
            Job ID          Username Queue    Jobname    SessID NDS TSK Memory Time  S Time
            --------------- -------- -------- ---------- ------ --- --- ------ ----- - -----
            11.pbs-host     vagrant  workq    STDIN       18685   1   1    --    --  R 00:00

            #ssh pbs-mom
            #ps -ef | grep sleep

            vagrant  18707 18706  0 07:06 ?        00:00:00 sleep 200               //host에서 제출한 job이 
            vagrant  18734 18712  0 07:10 pts/0    00:00:00 grep sleep              //스케줄링 됨
            #sudo /etc/init.d/pbs stop                //pbs-host1 stop
            
            #ps -ef | grep pbs            //pbs-host2에서 실행
            #root      2474     1  0 05:37 ?        00:00:00 /sbin/dhclient -H pbs-host2 -1 -q -cf /etc/dhcp/dhclient-eth0.conf -lf /var/lib/dhclient/dhclient-eth0.leases -pf /var/run/dhclient-eth0.pid eth0
            #root      9320     1  0 06:45 ?        00:00:00 /opt/pbs/sbin/pbs_comm
            #root      9337     1  0 06:45 ?        00:00:00 /opt/pbs/sbin/pbs_server.bin
            
            #ps -ef | grep pbs
            #root      2474     1  0 05:37 ?        00:00:00 /sbin/dhclient -H pbs-host2 -1 -q -cf /etc/dhcp/dhclient-eth0.conf -lf /var/lib/dhclient/dhclient-eth0.leases -pf /var/run/dhclient-eth0.pid eth0
            #root      9320     1  0 06:45 ?        00:00:00 /opt/pbs/sbin/pbs_comm
            #root      9337     1  0 06:45 ?        00:00:00 /opt/pbs/sbin/pbs_server.bin
            #root      9528     1  0 07:01 ?        00:00:00 /opt/pbs/sbin/pbs_ds_monitor monitor
            #postgres  9556     1  0 07:01 ?        00:00:00 /usr/bin/postgres -D /data/pbs/datastore -p 15007          //일정시간이후 pbs-host1의 db가 pbs-host2로 넘어온것을 확인
            #postgres  9724  9556  0 07:01 ?        00:00:00 postgres: postgres pbs_datastore 127.0.0.1(49662) idle
            #root      9730     1  0 07:01 ?        00:00:00 /opt/pbs/sbin/pbs_sched
            
            

            
```
# pbs mom에서 리소스 부족으로 seg fault 발생시 해당파일의 끝에 ulimit -s unlimits 추가
/usr/pbs/lib/init.d/limits.pbs_mom

```
   
