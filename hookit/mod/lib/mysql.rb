module Hooky
  module Mysql

    BOXFILE_DEFAULTS = {
      # global settings
      before_deploy: {type: :array, of: :string, default: []},
      after_deploy:  {type: :array, of: :string, default: []},

      # myisam
      mysql_myisam_key_buffer_size:         {type: :byte, default: nil},
      mysql_myisam_sort_buffer_size:        {type: :byte, default: '1M'},
      mysql_myisam_read_buffer_size:        {type: :byte, default: '1M'},
      mysql_myisam_read_rnd_buffer_size:    {type: :byte, default: '4M'},
      mysql_myisam_myisam_sort_buffer_size: {type: :byte, default: '64M'},
      mysql_myisam_recover:                 {type: :string, default: 'DEFAULT', from: ['DEFAULT', 'BACKUP', 'FORCE', 'QUICK']},

      # innodb
      mysql_innodb_buffer_pool_size:         {type: :byte, default: nil},
      mysql_innodb_additional_mem_pool_size: {type: :byte, default: '20M'},
      mysql_innodb_log_buffer_size:          {type: :byte, default: '8M'},
      mysql_innodb_flush_log_at_trx_commit:  {type: :integer, default: 2},
      mysql_innodb_lock_wait_timeout:        {type: :integer, default: 50},
      mysql_innodb_doublewrite:              {type: :integer, default: 0},
      mysql_innodb_io_capacity:              {type: :integer, default: 1500},
      mysql_innodb_read_io_threads:          {type: :integer, default: 8},
      mysql_innodb_write_io_threads:         {type: :integer, default: 8},

      # general
      mysql_slow_query_log:           {type: :on_off, default: 'on'},
      mysql_performance_schema:       {type: :on_off, default: 'off'},
      mysql_table_open_cache:         {type: :integer, default: 64},
      mysql_thread_cache_size:        {type: :integer, default: nil},
      mysql_query_cache_type:         {type: :integer, default: 0, from: [0, 1, 2]},
      mysql_back_log:                 {type: :integer, default: nil},
      mysql_thread_concurrency:       {type: :integer, default: nil},
      mysql_max_connections:          {type: :integer, default: nil},
      mysql_max_allowed_packet:       {type: :byte, default: '24M'},
      mysql_max_join_size:            {type: :integer, default: 9223372036854775807},
      mysql_net_buffer_length:        {type: :byte, default: '2K'},
      mysql_group_concat_max_len:     {type: :integer, default: 1024},
      mysql_thread_stack:             {type: :byte, default: '256K'},
      mysql_tmp_table_size:           {type: :byte, default: '64M'},
      mysql_max_heap_table_size:      {type: :byte, default: '64M'},
      mysql_plugins:                  {type: :array, of: :string, default: [], from: ['archive', 'blackhole', 'federated', 'audit_log', 'disable_myisam', 'sphinx']},
      mysql_allow_suspicious_udfs:    {type: :on_off, default: nil},
      mysql_ansi:                     {type: :on_off, default: nil},
      mysql_ft_max_word_len:          {type: :integer, default: nil},
      mysql_ft_min_word_len:          {type: :integer, default: nil},
      mysql_ft_query_expansion_limit: {type: :integer, default: nil},
      mysql_binlog:                   {type: :on_off, default: nil},
      mysql_event_scheduler:          {type: :on_off, default: 'off'},
      mysql_ft_stopword_file:         {type: :file, default: nil}
    }

    def plugin_info(plugin)
      plugins = {
        'archive'   =>      {name: 'ARCHIVE', soname: 'ha_archive.so'},
        'blackhole' =>      {name: 'BLACKHOLE', soname: 'ha_blackhole.so'},
        'federated' =>      {name: 'FEDERATED', soname: 'ha_federated.so'},
        'audit_log' =>      {name: 'audit_log', soname: 'audit_log.so'},
        'disable_myisam' => {name: 'DISABLE_MYISAM', soname: 'dm.so'},
        'sphinx' =>         {name: 'sphinx', soname: 'ha_sphinx.so'}
      }
      plugins[plugin]
    end

    def plugins(boxfile)
      boxfile[:mysql_plugins].map {|plugin| plugin_info(plugin)}
    end

    def can_login?(user, password)
      `/data/bin/mysql \
        -u #{user} \
        --password=#{password} \
        -h 127.0.0.1 \
        -e \"SHOW DATABASES;\"`
      $?.exitstatus == 0
    end

  end
end
