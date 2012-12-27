module SensitiveFileChecker
  def self.files
    %W{
      #{Rails.root}/config/secret.token
      #{Rails.root}/config/secret.key
      #{Rails.root}/config/chorus.properties
    }
  end

  def self.mode(file)
    File.stat(file).mode & 0777
  end

  def self.check
    unprotected_files.empty?
  end

  def self.unprotected_files
    files.select { |file| mode(file) != 0600 }
  end
end