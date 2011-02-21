#!/usr/bin/env ruby
#(__FILE__)
require 'yaml'
require File.join(File.dirname(__FILE__), 'write_templated_file')

# TODO: Interpolate database credentials
# source the database credentials.
# Expect :database, :username, :password

class DatabaseConfigurator
  def initialize(ymlfile, options={})
    #dbinfo['database']
    #dbinfo['username']
    #dbinfo['password']
    @dbinfo = YAML.load_file('/var/lib/jenkins/dbinfo.yml')
    @options = ENV.to_hash
    @options.merge!(@dbinfo || {})
    @options.merge!(options)
    @options['database'] = ci_database_name
    @config_dir = File.join(options['WORKSPACE']||'.' , 'config')
  end
  
  # The database name may include a wildcard. If so, use build parameters.
  def ci_database_name
    ci_job = @options['CI_JOB'] || 'default'
    ci_branch = @options['CI_BRANCH'] || 'master'
    @dbinfo['database'].gsub(/%/, "#{ci_job}_#{ci_branch}")
  end
  
  def interpolate_template_database_config
    app_prefix = @options['APP_PREFIX'] || 'CI'
    t = Templator.new  # The templator includes ENV by default.
    t.with_options(@options)
    t.with_options( {
                      "#{app_prefix}_DB_NAME" => @options['database'],
                      "#{app_prefix}_DB_USER" => @options['username'],
                      "#{app_prefix}_DB_PASSWORD" => @options['password']
                    } )
    t.with_directory(@config_dir)
    
    t.interpolate_files_like("database.yml")
  end
  
  def interpolate_existing_database_config
    dbinfo = {}
    @dbinfo.find_all()
    @dbinfo.each_key { |key| dbinfo[key] = @options[key] }
  
    file=File.join(@config_dir), 'database.yml'
    config = YAML.load_file(file)
    config.each do |env, settings|
      settings.merge!(dbinfo)
    end
    
    File.open(file, 'w') do |f|
      YAML.dump(config, f)
    end
  end
  
end

if $0 == __FILE__
  c = DatabaseConfigurator.new('/var/lib/jenkins/dbinfo.yml')
  c.interpolate_template_database_config
end
