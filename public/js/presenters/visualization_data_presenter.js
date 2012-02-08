;(function(ns) {
    ns.presenters.visualizations = {};

    ns.presenters.visualizations.Timeseries = function(task, options) {
        this.task = task;
        this.options = options;
    };

    _.extend(ns.presenters.visualizations.Timeseries.prototype, {
        present: function() {
            var rows = this.task.get("rows");
            var xs = _.pluck(rows, this.options.x);
            var ys = _.pluck(rows, this.options.y);
            var data = _.map(rows, function(_row, i) {
                return { x: xs[i], y: ys[i] };
            });

            return _.extend(data, {
                maxX : _.max(xs),
                maxY : _.max(ys),
                minX : _.min(xs),
                minY : _.min(ys)
            });
        }
    });

    ns.presenters.visualizations.Frequency = function(task, options) {
        this.task = task;
        this.options = options;
    };

    _.extend(chorus.presenters.visualizations.Frequency.prototype, {
        present: function() {
            return _.map(this.task.get("rows"), function(row) {
                return {bucket: row.bucket, count: row.count};
            });
        }
    });

    ns.presenters.visualizations.Boxplot = function(task, options) {
        this.task = task;
        this.options = options;
    };

    _.extend(ns.presenters.visualizations.Boxplot.prototype, {
        present: function() {
            var boxes = _.map(this.task.get("rows"), function(row) {
                return {
                    min:           row.min,
                    median:        row.median,
                    bucket:        row.bucket,
                    max:           row.max,
                    firstQuartile: row.firstQuartile,
                    thirdQuartile: row.thirdQuartile,
                    percentage:    row.percentage
                };
            });

            var orderedBoxes = _.sortBy(boxes, function(box) {
                return -1 * parseInt(box.percentage);
            });

            orderedBoxes.minY = _.min(_.pluck(orderedBoxes, "min"));
            orderedBoxes.maxY = _.max(_.pluck(orderedBoxes, "max"));

            return orderedBoxes;
        }
    });

    chorus.presenters.visualizations.Histogram = function(task, options) {
        this.task = task;
        this.options = options;
    }

    _.extend(chorus.presenters.visualizations.Histogram.prototype, {
        present: function() {
            return _.map(this.task.get("rows"), function(row) {
                return {bin: row.bin, frequency: row.frequency};
            });
        }
    });

    chorus.presenters.visualizations.Heatmap = function(task, options) {
        this.task = task;
        this.options = options;
    }

    _.extend(chorus.presenters.visualizations.Heatmap.prototype, {
        present: function() {
            var rows = _.clone(this.task.get("rows"));
            var xs = _.map(rows, function(row) {
                var numbers = row.xLabel.match(/[\d\.]+/g);
                return _.map(numbers, parseFloat);
            });
            var ys = _.map(rows, function(row) {
                var numbers = row.yLabel.match(/[\d\.]+/g);
                return _.map(numbers, parseFloat);
            });
            var values = _.pluck(rows, 'value');

            rows.minX = _.min(_.flatten(xs));
            rows.minY = _.min(_.flatten(ys));
            rows.maxX = _.max(_.flatten(xs));
            rows.maxY = _.max(_.flatten(ys));

            rows.minValue = _.min(values)
            rows.maxValue = _.max(values)

            return rows;
        }
    })

})(chorus);
