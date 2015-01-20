namespace :caching do
  desc "THis task will iterate throgh the workspaces in the database and add them to the cache so that users will not experience long delay while loading workspaces on the page"
  task :workspaces => :environment do
    users = User.all
    users.each do | user|
      options = {:user => user,:succinct => true, :show_latest_comments => true, :cached => true, :namespace => "dashboard:workspaces"}
      workspaces = Workspace.workspaces_for(user)
      workspaces = workspaces.includes(Workspace.eager_load_associations).order("lower(name) ASC, id")
      print "Caching workspaces for #{user.username} "
      workspaces.each do |workspace|
        Presenter.present(workspace, nil, options)
        #workspace.refresh_cache
        print "."
        $stdout.flush
      end
      printf " done\n"
    end
  end

  desc "TODO"
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

  desc "TODO"



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

  desc "TODO"
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
