class FixtureMiddleware
  def call(env)
    response_lines = []
    Dir.glob("spec/javascripts/fixtures/**/*.json") do |file|
      fixture_name = file[("spec/javascripts/fixtures/".length)...(-(".json".length))]
      this_response = [%{<script type="application/json" data-fixture-path="#{fixture_name}">}]
      this_response << IO.read(file)
      this_response << %{</script>}
      response_lines << this_response.join()
    end
    [200, {"Content-Type" => "text/html"}, response_lines]
  end
end

class MessageMiddleware
  def call(env)
    [200, {"Content-Type" => "text/html"}, [IO.read("public/messages/Messages_en.properties")]]
  end
end

class DummyMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    path = env['PATH_INFO']

    fake_headers =
      case path
      when /\.js$/
        nil
      when /\/.*(image|thumbnail)/, /\.(png|gif|jpg)/
        { "Content-Type" => "image/jpeg" }
      when /fonts/
        { "Content-Type" => "application/octet-stream" }
      when /\/file\/[^\/]+$/
        { "Content-Type" => "text/plain" }
      when /\/edc\//
        { "Content-Type" => "application/json" }
      end

    if fake_headers
      [200, fake_headers, []]
    else
      @app.call(env)
    end
  end
end

Jasmine.configure do |config|
  config.boot_dir = Rails.root.join('spec/javascripts/support/old-jasmine-core').to_s
  config.boot_files = lambda { [Rails.root.join('spec/javascripts/support/old-jasmine-core/boot.js').to_s] }

  config.add_rack_path('/messages/Messages_en.properties', lambda { MessageMiddleware.new })
  config.add_rack_path('/__fixtures', lambda { FixtureMiddleware.new })
  config.add_rack_app(DummyMiddleware)
end