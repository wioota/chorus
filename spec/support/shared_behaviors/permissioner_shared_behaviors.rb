shared_examples "a permissioned model" do


  it "creates a chorus class and object when created" do
    chorus_class = ChorusClass.find_by_name(model.class.name)
    expect(chorus_class).to_not be_nil

    chorus_object = chorus_class.chorus_objects.find_by_instance_id(model.id)
    expect(chorus_object).to_not be_nil
  end

  it "initializes the default roles if they exist" do
    return if !model.class.const_defined? 'OBJECT_LEVEL_ROLES' # Some permissioned objects don't use object level roles

    object_roles_symbols = model.class::OBJECT_LEVEL_ROLES
    object_roles = model.object_roles
    symbols = object_roles.map {|role| role.name.to_sym }

    expect(object_roles_symbols).to eq(symbols)
  end

end