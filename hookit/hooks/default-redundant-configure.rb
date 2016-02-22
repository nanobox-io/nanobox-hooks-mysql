
include Hooky::Mysql
boxfile = converge( BOXFILE_DEFAULTS, payload[:boxfile] )

total_mem = `vmstat -s | grep 'total memory' | awk '{print $1}'`.to_i
cgroup_mem = `cat /sys/fs/cgroup/memory/memory.limit_in_bytes`.to_i
memcap = [ total_mem / 1024, cgroup_mem / 1024 / 1024 ].min

# set my.cnf
template '/data/etc/my.cnf' do
  source 'my-galera.cnf.erb'
  mode 0644
  variables ({
    payload: payload,
    boxfile: boxfile,
    type:    'mysql',
    memcap:  memcap,
    version: version(),
    plugins: plugins(boxfile)
  })
  owner 'gonano'
  group 'gonano'
end

template '/data/bin/start-mysql.sh' do
  source 'start-mysql.sh.erb'
  owner 'gonano'
  group 'gonano'
  mode 0755
  variables ({
    payload: payload
  })
end

template '/etc/service/db/run' do
  mode 0755
  variables ({ exec: "/data/bin/start-mysql.sh 2>&1" })
end

