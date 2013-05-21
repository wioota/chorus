class ClearFileCacheStore < ActiveRecord::Migration
  def up
    cache_path = Rails.root + 'tmp/cache'
    cache_path.rmtree
  end
end
