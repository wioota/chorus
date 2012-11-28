$:.unshift File.expand_path("../../../lib/kaggle", __FILE__)
$:.unshift File.expand_path("../../../app/models", __FILE__)

module KaggleSpecHelpers
  def kaggle_users_api_result
    JSON.parse(File.read(Rails.root + "lib/kaggle/userApi.json"))['users'].map { |data|
      Kaggle::User.new(data)
    }
  end
end