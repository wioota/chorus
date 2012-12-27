unless Rails.env.production?
  namespace :jshint do
    task :specs do
      include_paths = JSHint::Utils.paths_from_command_line('paths')
      exclude_paths = JSHint::Utils.paths_from_command_line('exclude_paths')

      if include_paths && exclude_paths.nil?
        # if you pass paths= on command line but not exclude_paths=, and you have exclude_paths
        # set in the config file, then the old exclude pattern will be used against the new
        # include pattern, which may be very confusing...
        exclude_paths = []
      end

      lint = JSHint::Lint.new paths: include_paths, exclude_paths: exclude_paths, config_path: 'config/jshint_specs.yml'
      lint.run
    end

    task :all => ['jshint', 'jshint:specs']

    task :changed do
      files = `git diff --cached --name-only --diff-filter=ACM`.split("\n")
      javascript = files.select { |file| file.ends_with?('.js') }
      production_js = javascript.select { |file| file.starts_with?('app/assets') }.join(',')
      spec_js = javascript.select { |file| file.starts_with?('spec') }.join(',')

      unless spec_js.empty?
        ENV['paths'] = spec_js
        Rake::Task['jshint:specs'].invoke
      end

      unless production_js.empty?
        ENV['paths'] = production_js
        Rake::Task['jshint'].invoke
      end
    end
  end
end