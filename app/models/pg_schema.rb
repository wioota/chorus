class PgSchema < Schema
  include SandboxSchema

  def class_for_type(type)
    type == 'r' ? PgTable : PgView
  end
end
