class LinkedTableauWorkfilePresenter < WorkfilePresenter

  def to_hash
    super.merge(tableau_hash)
  end

  def tableau_hash
    {
        :workbook_url => model.workbook_url,
        :workbook_name => model.workbook_name,
        :version_info => {
            :updated_at => model.created_at
        }
    }
  end

  def complete_json?
    true
  end

  private
  def latest_workfile_version
    OpenStruct.new id: nil
  end

  def has_draft(user)
    false
  end
end