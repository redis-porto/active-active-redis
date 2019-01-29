# active-active-redis


### Download Git and downlaod Dynomite Code, Build Dynomite 

```bash
sudo yum install git -y
sudo git clone https://github.com/Netflix/dynomite.git
cd dynomite
sudo yum install -y autoconf automake
sudo yum install -y libtool
sudo yum install -y openssl-devel
sudo autoreconf -fvi
sudo ./configure --enable-debug=log
sudo make
```

### Testing the Installation 

```bash
src/dynomite -h
```

### Install Redis cluster on Amazon Linux OS

```bash
sudo yum -y upgrade
sudo yum install -y gcc*
sudo yum install -y tcl
sudo wget http://download.redis.io/releases/redis-5.0.3.tar.gz
sudo tar xzf redis-5.0.3.tar.gz
cd redis-5.0.3
cd deps ; sudo make hiredis jemalloc linenoise lua ; cd ..
sudo make
sudo make test
sudo make install
cd utils ; sudo chmod +x install_server.sh ; sudo ./install_server.sh
```
It will ask you for the Redis Executable - it should be: /usr/local/bin/redis-server
Them you can check for redis service 

```bash
sudo service redis_6379 status
```

### Config Dyno for Single Redis
```bash
sudo touch redis_single.yml
sudo vi redis_single.yml
```

ADD this content
```bash
dyn_o_mite:
  dyn_listen: 127.0.0.1:8101
  data_store: 0
  listen: 0.0.0.0:8102
  dyn_seed_provider: simple_provider 
  servers:
  - 127.0.0.1:6379:1
  tokens: 437425602
```

### Run Dyno
```bash
sudo src/dynomite -c redis_single.yml
```


```bash

#!/bin/bash
# Set core affinity for redis and dynomite processes
#

# Requires setting the EC2 Instance type as ENV variable.
# If Dynomite is used outside of AWS environment,
# the core affinity script can be configured accordingly.
echo "$EC2_INSTANCE_TYPE"

if [ "$EC2_INSTANCE_TYPE" == "r5d.large" ]; then
   dynomite_pid=`pgrep -f $DYN_DIR/bin/dynomite`
   echo "dynomite pid: $dynomite_pid"
   taskset -pac 2 $dynomite_pid

   redis_pid=`ps -ef | grep 6379 | grep redis | awk -F' '  '{print $2}'`
   echo "redis pid: $redis_pid"
   taskset -pac 1 $redis_pid

else

   dynomite_pid=`pgrep -f $DYN_DIR/bin/dynomite`
   echo "dynomite pid: $dynomite_pid"
   taskset -pac 2,5,6 $dynomite_pid

   redis_pid=`ps -ef | grep 6379 | grep redis | awk -F' '  '{print $2}'`
   echo "redis pid: $redis_pid"
   taskset -pac 3,7 $redis_pid

fi
```bash

