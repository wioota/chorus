class HadoopInstanceAccess < AdminFullAccess
  def edit?(hadoop_instance)
    hadoop_instance.owner == current_user
  end

  def show?(hadoop_instance)
    true
  end
end
