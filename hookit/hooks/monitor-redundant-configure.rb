
template '/data/bin/start-garbd.sh' do
  owner 'gonano'
  group 'gonano'
  mode 0755
  variables ({
    payload: payload
  })
end

# Import service (and start)
directory '/etc/service/monitor' do
  recursive true
end

directory '/etc/service/monitor/log' do
  recursive true
end

template '/etc/service/monitor/log/run' do
  mode 0755
  source 'log-run.erb'
  variables ({ svc: "monitor" })
end

template '/etc/service/monitor/run' do
  mode 0755
  variables ({ exec: "/data/bin/start-garbd.sh 2>&1" })
end

# Narc Setup
template '/opt/gonano/etc/narc.conf' do
  source 'monitor-narc.conf.erb'
  variables ({
    uid: payload[:uid],
    app: "nanobox",
    logtap: payload[:logtap_host]
  })
end
