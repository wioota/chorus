class ImportCanceler
  def self.run
    new.run
  end

  def run
    while true
      cancel_imports
      sleep 5
    end
  end

  def cancel_imports
    imports_awaiting_cancel.each { |import| import.cancel false }
  end

  def imports_awaiting_cancel
    Import.where(:success => nil).
        where(Import.arel_table[:started_at].not_eq(nil)).
        where(Import.arel_table[:canceled_at].not_eq(nil))
  end
end