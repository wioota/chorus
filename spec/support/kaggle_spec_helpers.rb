module KaggleSpecHelpers
  def kaggle_users_api_result
    JSON.parse(File.read(Rails.root + "lib/kaggle/kaggleSearchResults.json"))['users'].map { |data|
      Kaggle::User.new(data)
    }
  end
end