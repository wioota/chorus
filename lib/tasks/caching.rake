namespace :chorus do

  desc "Run all caching tasks for chorus application"
  task :caching, [:type] => :environment do |task, args|
    #print "arg = #{args[:type]}\n"
    #print "arg = #{args.extras}\n"

    ChorusConfig.instance.with_temporary_config( { :database_login_timeout => 1} ) do
      if args[:type] == nil || args[:type] == 'all'
        print "\n================ Caching workspaces START ==================\n"
        Rake::Task["chorus:workspaces"].reenable
        Rake::Task["chorus:workspaces"].invoke
        print "================ Caching workspaces FINISH =================\n\n"
        print "\n================ Caching activities START ==================\n"
        Rake::Task["chorus:activities"].reenable
        Rake::Task["chorus:activities"].invoke
        print "================ Caching activities FINISH =================\n\n"
        print "\n================ Caching datasets START ==================\n"
        Rake::Task["chorus:datasets"].reenable
        Rake::Task["chorus:datasets"].invoke
        print "================ Caching datasets FINISH =================\n\n"
        print "\n================ Caching workfiles START ==================\n"
        Rake::Task["chorus:workfiles"].reenable
        Rake::Task["chorus:workfiles"].invoke
        print "================ Caching workfiles FINISH =================\n\n"
      else
        print "\n================ Caching  #{args[:type]}  START ==================\n"
        Rake::Task["chorus:#{args[:type]}"].reenable
        Rake::Task["chorus:#{args[:type]}"].invoke
        print "================ Caching #{args[:type]} FINISH =================\n\n"
        args.extras.each do |arg|
          print "\n================ Caching #{arg} START ==================\n"
          Rake::Task["chorus:#{arg}"].reenable
          Rake::Task["chorus:#{arg}"].invoke
          print "================ Caching #{arg} FINISH =================\n\n"
        end
      end
    end
  end

  desc "This task will iterate through the workspaces in the database and add them to the cache so that users will not experience long delay \
while loading workspaces on the page"
  task :workspaces => :environment do
    users = User.all
    users.each do | user|
      options = {:user => user,:succinct => true, :show_latest_comments => true, :cached => true, :namespace => "home:workspaces"}
      workspaces = Workspace.workspaces_for(user)
      workspaces = workspaces.includes(Workspace.eager_load_associations).order("lower(name) ASC, id")
      print "Caching workspaces for #{user.username} "
      workspaces.each do |workspace|
        options = {:user => user,:succinct => true, :show_latest_comments => true, :cached => true, :namespace => "home:workspaces"}
        Presenter.present(workspace, nil, options)
        options = {:user => user,:succinct => false, :show_latest_comments => true, :cached => true, :namespace => "workspaces:workspaces"}
        Presenter.present(workspace, nil, options)
        #workspace.refresh_cache
        print "."
        $stdout.flush
      end
      printf " done\n"
    end
  end

  desc "This task will iterate through the activity stream for each user in the database and add them to the cache so that users will not experience long delay \
while loading activity stream on the page"
  task :activities => :environment do
    users = User.all
    users.each do | user|
      options = {:user => user, :activity_stream => true, :succinct => true, :workfile_as_latest_version => true, :cached => true, :namespace => "dashboard:activities"}
      events = user.events
      print "Caching activities for #{user.username} "
      events.each do |event|
        Presenter.present(event, nil, options)
        print "."
        $stdout.flush
      end
      printf " done\n"
    end
  end



  desc "This task will iterate through the datasets in the database and add them to the cache so that users will not experience long delay \
while loading datasets on the page"
  task :datasets => :environment do
    users = User.all
    params = {}
    users.each do | user|
      workspaces = Workspace.workspaces_for(user)
      workspaces = workspaces.includes(Workspace.eager_load_associations).order("lower(name) ASC, id")
      print "Caching datasets for #{user.username} "
      workspaces.each do |workspace|
        options = {:user => user, :workspace => workspace, :cached => true, :namespace => "workspace:datasets" }
        datasets = workspace.datasets(user, params).includes(Dataset.eager_load_associations).list_order
        if datasets != nil && datasets.size != 0
          Presenter.present(datasets, nil, options)
          print "."
        else
          print "x"
        end
        $stdout.flush
      end
      printf " done\n"
    end
  end

  desc "This task will iterate through the workfiles in the database and add them to the cache so that users will not experience long delay \
while loading workfiles on the page"
  task :workfiles => :environment do
    users = User.all
    params = {}
    users.each do | user|
      workspaces = Workspace.workspaces_for(user)
      workspaces = workspaces.includes(Workspace.eager_load_associations).order("lower(name) ASC, id")
      print "Caching workfiles for #{user.username} "
      workspaces.each do |workspace|
        options = {:user => user, :workfile_as_latest_version => true, :list_view => true, :cached => true, :namespace => "workspace:workfiles"}
        workfiles = workspace.filtered_workfiles(params)
        Presenter.present(workfiles, nil, options)
        print "."
        $stdout.flush
      end
      printf " done\n"
    end

  end

end
