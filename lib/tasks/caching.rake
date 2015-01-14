namespace :caching do
  desc "THis task will iterate throgh the workspaces in the database and add them to the cache so that users will not experience long delay while loading workspaces on the page"
  task :workspaces => :environment do
    users = User.all
    users.each do | user|
      options = {:user => user,:succinct => true, :show_latest_comments => true, :cached => true, :namespace => "workspaces"}
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
      options = {:user => user, :activity_stream => true, :succinct => true, :workfile_as_latest_version => true, :cached => true, :namespace => "activities"}
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
  task :workfiles => :environment do
  end

end
