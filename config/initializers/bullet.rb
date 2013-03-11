if Rails.env.development?
  Rails.configuration.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.rails_logger = true
  end
end