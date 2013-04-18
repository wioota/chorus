require_relative '../../version'
require_relative '../task_helpers/package_maker'

namespace :package do
  task :check_clean_working_tree do
    unless ENV['IGNORE_DIRTY'] || system('git diff-files --quiet')
      puts "You have a dirty working tree. You must stash or commit your changes before packaging. Or run with IGNORE_DIRTY=true"
      exit(1)
    end
  end

  task :prepare_app => :check_clean_working_tree do
    Rake::Task[:'api_docs:package'].invoke
    system("rake assets:precompile RAILS_ENV=production RAILS_GROUPS=assets --trace") || exit(1)
    system("bundle exec jetpack .") || exit(1)
    PackageMaker.write_version
  end

  desc 'Generate binary installer'
  task :installer => :prepare_app do
    PackageMaker.make_installer
  end

  task :cleanup do
    PackageMaker.clean_workspace
  end
end

packaging_tasks = Rake.application.top_level_tasks.select { |task| task.to_s.match(/^package:/) }

last_packaging_task = packaging_tasks.last
Rake::Task[last_packaging_task].enhance do
  Rake::Task[:'package:cleanup'].invoke
end if last_packaging_task
