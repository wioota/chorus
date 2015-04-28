shared_examples "a permissioned model" do

  it "creates a chorus class and object when created" do
    chorus_class = ChorusClass.find_by_name(model.class.name)
    expect(chorus_class).to_not be_nil

    chorus_object = chorus_class.chorus_objects.find_by_instance_id(model.id)
    expect(chorus_object).to_not be_nil
  end

  it "initializes the default roles if they exist" do
    next if !model.class.const_defined? 'OBJECT_LEVEL_ROLES' # Some permissioned objects don't use object level roles

    object_roles_symbols = model.class::OBJECT_LEVEL_ROLES
    object_roles = model.object_roles
    symbols = object_roles.map {|role| role.name.to_sym }

    expect(object_roles_symbols).to eq(symbols)
  end

  describe "when adding permissions" do
    let (:role) { roles(:a_role) }
    let (:permission) { model.class::PERMISSIONS.first }

    it "should create .permissions on the chorus class" do
      old_count = ChorusClass.find_by_name(model.class.name).permissions.count
      model.class.set_permissions_for(role, permission)
      new_count = ChorusClass.find_by_name(model.class.name).permissions.count

      expect(new_count).to eq(old_count + 1)
    end


  end

  describe "permission_symbols_for" do
    let (:role) { roles(:a_role) }
    let (:user) { users(:admin) }
    let (:permission) { model.class::PERMISSIONS.first }
    it "should_return the correct permission_symbol" do
      user.roles << role
      model.class.set_permissions_for(role, permission)
      expect(model.class.permission_symbols_for(user)).to eq(Array.wrap(permission))
    end
  end

end