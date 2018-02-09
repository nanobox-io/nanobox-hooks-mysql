module Hooky
  module Mysql

    DEFAULT_ROOT_PRIVILEGES = [
      {
        privilege: "ALL PRIVILEGES",
        on: "*.*",
        with_grant: true
      }
    ]

    DEFAULT_PRIVILEGES = [
      {
        privilege: "ALL PRIVILEGES",
        on: "gonano.*",
        with_grant: true
      },
      {
        privilege: "PROCESS",
        on: "*.*",
        with_grant: false
      },
      {
        privilege: "SUPER",
        on: "*.*",
        with_grant: false
      }
    ]

    DEFAULT_ROOT_META = {
      privileges: DEFAULT_ROOT_PRIVILEGES,
      databases: []
    }

    DEFAULT_META = {
      privileges: DEFAULT_PRIVILEGES,
      databases: ["gonano"]
    }

    DEFAULT_USERS = [
      {
        username: "root",
        meta: DEFAULT_ROOT_META
      },
      {
        username: "nanobox",
        meta: DEFAULT_META
      }
    ]

    USER_META_PRVILIGES_DEFAULTS = {
      privilege:    {type: :string, from: ["ALL", "ALL PRIVILEGES", "ALTER", "ALTER ROUTINE", "CREATE", "CREATE ROUTINE", "CREATE TABLESPACE", "CREATE TEMPORARY TABLES", "CREATE USER", "CREATE VIEW", "DELETE", "DROP", "EVENT", "EXECUTE", "FILE", "GRANT OPTION", "INDEX", "INSERT", "LOCK TABLES", "PROCESS", "PROXY", "REFERENCES", "RELOAD", "REPLICATION CLIENT", "REPLICATION SLAVE", "SELECT", "SHOW DATABASES", "SHOW VIEW", "SHUTDOWN", "SUPER", "TRIGGER", "UPDATE", "USAGE"], default: "SELECT"},
      on:           {type: :string, default: 'gonano.*'},
      with_grant:   {type: :on_off, default: false}
    }

    USER_META_DEFAULTS = {
      privileges:    {type: :array, of: :hash, template: USER_META_PRVILIGES_DEFAULTS, default: DEFAULT_PRIVILEGES},
      databases:     {type: :array, of: :string, default: ["gonano"]}
    }

    USER_DEFAULTS = {
      username:      {type: :string, default: 'gonano'},
      meta:          {type: :hash, template: USER_META_DEFAULTS, default: DEFAULT_META}
    }

    CONFIG_DEFAULTS = {
      # global settings
      before_deploy:                   {type: :array, of: :string, default: []},
      after_deploy:                    {type: :array, of: :string, default: []},
      hook_ref:                        {type: :string, default: "stable"},

      # myisam
      myisam_key_buffer_size:          {type: :byte, default: nil},
      myisam_sort_buffer_size:         {type: :byte, default: '1M'},
      myisam_read_buffer_size:         {type: :byte, default: '1M'},
      myisam_read_rnd_buffer_size:     {type: :byte, default: '4M'},
      myisam_myisam_sort_buffer_size:  {type: :byte, default: '64M'},
      myisam_recover:                  {type: :string, default: 'DEFAULT', from: ['DEFAULT', 'BACKUP', 'FORCE', 'QUICK']},

      # innodb
      innodb_buffer_pool_size:         {type: :byte, default: nil},
      innodb_additional_mem_pool_size: {type: :byte, default: '20M'},
      innodb_log_buffer_size:          {type: :byte, default: '8M'},
      innodb_flush_log_at_trx_commit:  {type: :integer, default: 2},
      innodb_lock_wait_timeout:        {type: :integer, default: 50},
      innodb_doublewrite:              {type: :integer, default: 0},
      innodb_io_capacity:              {type: :integer, default: 1500},
      innodb_read_io_threads:          {type: :integer, default: 8},
      innodb_write_io_threads:         {type: :integer, default: 8},

      # general
      slow_query_log:                  {type: :on_off, default: 'on'},
      performance_schema:              {type: :on_off, default: 'off'},
      table_open_cache:                {type: :integer, default: 64},
      thread_cache_size:               {type: :integer, default: nil},
      query_cache_type:                {type: :integer, default: 0, from: [0, 1, 2]},
      back_log:                        {type: :integer, default: nil},
      thread_concurrency:              {type: :integer, default: nil},
      max_connections:                 {type: :integer, default: nil},
      max_allowed_packet:              {type: :byte, default: '24M'},
      max_join_size:                   {type: :integer, default: 9223372036854775807},
      net_buffer_length:               {type: :byte, default: '16384'},
      group_concat_max_len:            {type: :integer, default: 1024},
      thread_stack:                    {type: :byte, default: '256K'},
      tmp_table_size:                  {type: :byte, default: '64M'},
      max_heap_table_size:             {type: :byte, default: '64M'},
      plugins:                         {type: :array, of: :string, default: [], from: ['archive', 'blackhole', 'federated', 'audit_log', 'disable_myisam', 'sphinx']},
      allow_suspicious_udfs:           {type: :on_off, default: nil},
      ansi:                            {type: :on_off, default: nil},
      ft_max_word_len:                 {type: :integer, default: nil},
      ft_min_word_len:                 {type: :integer, default: nil},
      ft_query_expansion_limit:        {type: :integer, default: nil},
      binlog:                          {type: :on_off, default: nil},
      event_scheduler:                 {type: :on_off, default: 'off'},
      ft_stopword_file:                {type: :file, default: nil},
      users:                           {type: :array, of: :hash, template: USER_DEFAULTS, default: DEFAULT_USERS}
    }

    def plugin_info(plugin)
      plugins = {
        'archive'   =>      {name: 'ARCHIVE', soname: 'ha_archive.so'},
        'blackhole' =>      {name: 'BLACKHOLE', soname: 'ha_blackhole.so'},
        'federated' =>      {name: 'FEDERATED', soname: 'ha_federated.so'},
        'audit_log' =>      {name: 'audit_log', soname: 'audit_log.so'},
        'disable_myisam' => {name: 'DISABLE_MYISAM', soname: 'disable_myisam.so'},
        'sphinx' =>         {name: 'sphinx', soname: 'ha_sphinx.so'}
      }
      plugins[plugin]
    end

    def plugins(boxfile)
      boxfile[:plugins].map {|plugin| plugin_info(plugin)}
    end

    def can_login?(user, password)
      `/data/bin/mysql \
        -u #{user} \
        --password=#{password} \
        -h 127.0.0.1 \
        -e \"SHOW DATABASES;\"`
      $?.exitstatus == 0
    end

    def version()
      output = `/data/bin/mysql --version`
      matches = /mysql\s+Ver\s+\d+\.\d+\s+Distrib\s(\d+)\.(\d+)\..*/.match(output)
      "#{matches[1]}.#{matches[2]}".to_f
    end

  end
end
