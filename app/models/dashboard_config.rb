class DashboardConfig

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def dashboard_items
    items = user.dashboard_items.where('location > -1').order(:location).map &:name

    if items.empty?
      items = DashboardItem::DEFAULT_MODULES
    end

    items
  end

  def update(modules)
    raise ApiValidationError.new(:base, :ONE_OR_MORE_REQUIRED) unless modules.present?

    User.transaction do
      user.dashboard_items.destroy_all
      available_modules = DashboardItem::ALLOWED_MODULES - modules
      modules.each_with_index do |name, i|
        user.dashboard_items.create!(:name => name, :location => i)
      end
      available_modules.each_with_index do |name|
        user.dashboard_items.create!(:name => name, :location => -1)
      end
    end
  end

  def set_options(module_name, option_string)
    User.transaction do
      user.dashboard_items.where(:name => module_name).update_all(:options => option_string)
    end
  end
end
