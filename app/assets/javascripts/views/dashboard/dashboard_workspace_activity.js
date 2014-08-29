chorus.views.DashboardWorkspaceActivity = chorus.views.Base.extend({
    constructorName: "DashboardWorkspaceActivity",
    templateName:"dashboard/workspace_activity",
    entityType: "workspace_activity",

    setup: function() {
        this.model = new chorus.models.DashboardData({});
        this.requiredResources.add(this.model);
        this.model.urlParams = { entityType: this.entityType };
        this.model.fetch();
    },

    postRender: function() {
        var $el = this.$(".chart");
        $el.html("");
        $el.addClass("visualization");

        var margin = {top: 20, right: 30, bottom: 30, left: 40},
            height = 340 - margin.top - margin.bottom,
            width = 960 - margin.left - margin.right;
        var format = d3.time.format.iso;

        var x = d3.time.scale()
            .range([0, width]);

        var y = d3.scale.linear()
            .range([height, 0]);

        var z = d3.scale.category20c();

        var xAxis = d3.svg.axis()
            .scale(x)
            .orient("bottom")
            .ticks(d3.time.weeks);

        var yAxis = d3.svg.axis()
            .scale(y)
            .orient("left")
            .ticks(4);

        var stack = d3.layout.stack()
            .offset("zero")
            .values(function(d) { return d.values; })
            .x(function(d) { return d.weekPart; })
            .y(function(d) { return d.eventCount; });

        var nest = d3.nest()
            .key(function(d) { return d.workspaceId; });

        var area = d3.svg.area()
            .interpolate("cardinal")
            .x(function(d) { return x(d.weekPart); })
            .y0(function(d) { return y(d.y0); })
            .y1(function(d) { return y(d.y0 + d.y); });

        var svg = d3.select($el[0])
            .append("svg")
                .attr("width", width + margin.left + margin.right)
                .attr("height", height + margin.top + margin.bottom)
            .append("g")
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        var data = _.each(this.model.get("data"), function(pt) {
            pt.weekPart = format.parse(pt.weekPart);
        }, this);

        var layers = stack(nest.entries(data));

        x.domain(d3.extent(data, function(d) { return d.weekPart; }));
        y.domain([0, d3.max(data, function(d) { return d.y0 + d.y; })]);

        svg.selectAll(".layer")
            .data(layers)
            .enter().append("path")
            .attr("class", "layer")
            .attr("d", function(d) { return area(d.values); })
            .style("fill", function(d, i) { return z(i); })
            .on('mouseover', _.bind(this.mouseover, this))
            .on('mouseout', _.bind(this.mouseout, this));

        svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + height + ")")
            .call(xAxis);

        svg.append("g")
            .attr("class", "y axis")
            .call(yAxis);

    },

    mouseover: function(data, index) {
        this._log('mouseover', data.key);
    },

    mouseout: function(data, index) {
        this._log('mouseout', data.key);
    },

    _log: function(type, msg) {
        chorus.toast("=> " + type + ": " + msg, { skipTranslation: true });
    }
});
