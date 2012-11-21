class HdfsEntryPresenter < Presenter

  def to_hash
    hash = {
        :id => model.id,
        :size => model.size,
        :name => model.name,
        :is_dir => model.is_directory,
        :is_binary => false,
        :last_updated_stamp => model.modified_at.nil? ? "" : model.modified_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
        :hadoop_instance => present(model.hadoop_instance),
        :ancestors => model.ancestors,
        :path => model.parent_path
    }

    if model.is_directory
      hash[:entries] = present model.entries if options[:deep]
      hash[:count] = model.content_count
    else
      hash[:contents] = model.contents if options[:deep]
    end

    hash
  end

  def complete_json?
    options[:deep]
  end
end
