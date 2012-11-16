class GnipInstanceAccess < AdminFullAccess
  def show?(gnip_instance)
    true
  end
end