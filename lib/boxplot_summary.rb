class BoxplotSummary
  def self.mean(a,b)
    (a + b) / 2.0
  end

  def self.summarize(ntiles_for_each_bin, number_of_bins)
    boxplot_entries = []

    all_bins = ntiles_for_each_bin.map{|r| r[:bucket]}.uniq
    total = ntiles_for_each_bin.inject(0) { |sum, r| sum + r[:count] }

    all_bins.each do |bin|
      quartiles_for_bin = ntiles_for_each_bin.select{ |r| r[:bucket] == bin }
      overall_min = quartiles_for_bin.first[:min]
      overall_max = quartiles_for_bin.last[:max]
      total_in_bin = quartiles_for_bin.inject(0) { |sum, r| sum + r[:count] }
      percentage = "%0.2f\%" % (total_in_bin.to_f / total * 100)

      boxplot_entries << {
          :bucket => bin,
          :count => total_in_bin,
          :min => overall_min,
          :max => overall_max,
          :percentage => percentage
      }.merge(quartiles(quartiles_for_bin))
    end

    return sort_entries(number_of_bins, boxplot_entries)
  end

  def self.sort_entries(number_of_bins, boxplot_entry)
    boxplot_entry = boxplot_entry.sort { |a, b| b[:percentage] <=> a[:percentage] }
    boxplot_entry = boxplot_entry[0..number_of_bins-1] if number_of_bins.present? && number_of_bins > 0
    return boxplot_entry
  end

  def self.quartiles(quartiles_for_bin)
    case quartiles_for_bin.length
      when 1
        median = first_quartile = third_quartile = quartiles_for_bin[0][:min]
      when 2
        median = mean(quartiles_for_bin[0][:max], quartiles_for_bin[1][:min])
        first_quartile = mean(quartiles_for_bin[0][:max], median)
        third_quartile = mean(quartiles_for_bin[1][:min], median)
      when 3
        median = quartiles_for_bin[1][:min]
        first_quartile = mean(quartiles_for_bin[0][:max], quartiles_for_bin[1][:min])
        third_quartile = mean(quartiles_for_bin[1][:max], quartiles_for_bin[2][:min])
      else
        median = mean(quartiles_for_bin[1][:max], quartiles_for_bin[2][:min])
        first_quartile = mean(quartiles_for_bin[0][:max], quartiles_for_bin[1][:min])
        third_quartile = mean(quartiles_for_bin[2][:max], quartiles_for_bin[3][:min])
    end

    return {:median => median,
            :first_quartile => first_quartile,
            :third_quartile => third_quartile}
  end
end
