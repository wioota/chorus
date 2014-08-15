class DashboardConfig

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def dashboard_items
    items = user.dashboard_items.order(:location).map &:name

    if items.empty?
      items = DashboardItem::DEFAULT_MODULES
    end

    items
  end

  def update(modules)
    raise ApiValidationError.new(:base, :ONE_OR_MORE_REQUIRED) unless modules.present?

    User.transaction do
      user.dashboard_items.destroy_all
      modules.each_with_index do |name, i|
        user.dashboard_items.create!(:name => name, :location => i)
      end
    end
  end
end
