module LicenseValidations

  def with_license
    yield License.instance unless open_chorus?
  end

  private

  def open_chorus?
    License.instance[:vendor] == License::OPEN_CHORUS
  end

end
