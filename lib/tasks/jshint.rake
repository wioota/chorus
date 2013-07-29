unless Rails.env.production?
  Rake::Task["jshint"].clear
  desc "Run JSHint check on selected Javascript files"
  task :jshint do
    include_paths = JSHint::Utils.paths_from_command_line('paths')

    lint = JSHint::Lint.new paths: include_paths, config_path: 'config/jshint.yml'
    lint.run
  end

  namespace :jshint do
    desc "Run JSHint check on selected Javascript spec files"
    task :specs do
      include_paths = JSHint::Utils.paths_from_command_line('paths')

      lint = JSHint::Lint.new paths: include_paths, config_path: 'config/jshint_specs.yml'
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