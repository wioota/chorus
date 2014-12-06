module ChorusLicenseValidator
  def self.log(*args)
    puts *args
  end

  def self.run(chorus_license)
    log "Checking Chorus license validity..."

    if !chorus_license.exists?
      log "  Warning: could not find Chorus license, using default 'openchorus' license"
      log "  Make sure the license is at #{chorus_license.path}"
    elsif chorus_license.expired?
      log "  Warning: the Chorus licence is expired, using default 'openchorus' license"
    end

    log "  License level is '#{chorus_license[:level]}'. If the below information is incorrect, double-check the Chorus license location and validity"
    log "    Vendor: #{chorus_license[:vendor]}"
    log "    Expiration date: #{chorus_license[:expires]}"
    log "    Number of admins: #{chorus_license[:admins]}"
    log "    Number of developers: #{chorus_license[:developers]}"
    log "    Number of collaborators: #{chorus_license[:collaborators]}"

    log ""
    log "-"*20
    return true
  end
end