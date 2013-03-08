RSpec.configure do |config|
  unless ENV['GPDB_HOST']
    warn "No Greenplum instance detected in environment variable 'GPDB_HOST'.  Skipping Greenplum integration tests.  See the project wiki for more information on running tests"
    config.filter_run_excluding :greenplum_integration => true
  end

  unless ENV['HADOOP_HOST']
    warn "No Hadoop data source detected in environment variable 'HADOOP_HOST'.  Skipping Hadoop integration tests.  See the project wiki for more information on running tests"
    config.filter_run_excluding :hdfs_integration => true
  end

  unless ChorusConfig.instance['kaggle'] && ChorusConfig.instance['kaggle']['api_key']
    warn "No Kaggle API key detected in chorus.properties.  Skipping Kaggle API tests.  See the project wiki for more information on running tests"
    config.filter_run_excluding :kaggle_api => true
  end

  if ENV['ORACLE_HOST']
    unless OracleIntegration.has_jar_file?
      warn "No Oracle driver found. Skipping Oracle integration tests"
      config.filter_run_excluding :oracle_integration => true
    end
  else
    warn "No Oracle instance detected in environment variable 'ORACLE_HOST'.  Skipping Oracle integration tests"
    config.filter_run_excluding :oracle_integration => true
  end
end