unless Rails.env.production?
  namespace :jasmine do
    Rake::Task['jasmine:server'].clear
    task :server => "jasmine:require" do
      port = ENV['JASMINE_PORT'] || 8888
      puts "your tests are here:"
      puts "  http://localhost:#{port}/"
      Jasmine.load_configuration_from_yaml
      require Rails.root.join('spec/javascripts/support/jasmine_config')
      app = Jasmine::Application.app(Jasmine.config)
      Jasmine::Server.new(port, app).start
    end
  end
end