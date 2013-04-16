class BoxplotSummary
  def self.mean(a,b)
    (a + b) / 2.0
  end

  def self.summarize(i, bins)
    new_map = []

    all_buckets = i.map{|r| r[:bucket]}.uniq
    total = i.inject(0) { |sum, r| sum + r[:count] }
    all_buckets.each do |bucket|
      quartile_data = i.select{ |r| r[:bucket] == bucket }
      min = quartile_data.first[:min]
      max = quartile_data.last[:max]
      count = quartile_data.inject(0) { |sum, r| sum + r[:count] }
      percentage = "%0.2f\%" % (count.to_f / total * 100)

      if quartile_data.length == 1
        median = first_quartile = third_quartile = quartile_data[0][:min]
      elsif quartile_data.length == 2
        median         = mean(quartile_data[0][:max], quartile_data[1][:min])
        first_quartile = mean(quartile_data[0][:max], median)
        third_quartile = mean(quartile_data[1][:min], median)
      elsif quartile_data.length == 3
        median = quartile_data[1][:min]
        first_quartile = mean(quartile_data[0][:max], quartile_data[1][:min])
        third_quartile = mean(quartile_data[1][:max], quartile_data[2][:min])
      else
        median = mean(quartile_data[1][:max], quartile_data[2][:min])
        first_quartile = mean(quartile_data[0][:max], quartile_data[1][:min])
        third_quartile = mean(quartile_data[2][:max], quartile_data[3][:min])
      end

      new_map << {:bucket => bucket,
                  :count => count,
                  :min => min,
                  :median => median,
                  :max => max,
                  :first_quartile => first_quartile,
                  :third_quartile => third_quartile,
                  :percentage => percentage}
    end

    new_map = new_map.sort {|a, b| b[:percentage] <=> a[:percentage] }
    new_map = new_map[0..bins-1] if bins.present? && bins > 0
    return new_map
  end
end
