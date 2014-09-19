chorus.views.DashboardWorkspaceActivity = chorus.views.Base.extend({
    constructorName: "DashboardWorkspaceActivity",
    templateName:"dashboard/workspace_activity",
    entityType: "workspace_activity",

    setup: function() {
        this.model = new chorus.models.DashboardData({});
        this.requiredResources.add(this.model);
        this.model.urlParams = { entityType: this.entityType };
        this.model.fetch();

        this.vis = {
            // Properties about data provided by server
            dataSettings: {
                date_format: d3.time.format.iso
            },

            // Data to be rendered.
            data: null,

            // Reference to the SVG canvas rendered into
            canvas: null,

            // Properties for each entity we'll include in the visualization
            entities: {
                // The stacked chart
                chart: {
                    // Reference to the domElement
                    domElement: null,
                    // Params we'll use during rendering
                    properties: {
                        margin: {
                            top:    20,
                            right:  30,
                            bottom: 30,
                            left:   40
                        },
                        get height () {
                            return 340 - this.margin.top - this.margin.bottom;
                        },
                        get width () {
                            return 960 - this.margin.left - this.margin.right;
                        },
                        // Function designating the area fill colors desired.
                        // See "categorical colors" in https://github.com/mbostock/d3/wiki/Ordinal-Scales
                        fillColors: d3.scale.category20c()
                    }
                },
                // Tooltip shown in the chart upon mouseover
                tooltip: {
                    // Reference to the domElement
                    domElement: null,
                    // Params we'll use during rendering
                    properties: {
                    }
                }
            }
        };
    },

    postRender: function() {
        // Load raw data used in visualization:
        // Our data looks like a flat array of objects. Example:
        /*   {
         "data": [{
         "date_part": "2014-09-18 00:00:00",
         "workspace_id": 1,
         "event_count": 0
         }, {
         "date_part": "2014-09-18 00:00:00",
         "workspace_id": 2,
         "event_count": 0
         }]
         }
         */
        var data = this.vis.data = _.each(
            this.model.get("data"),
            function(pt) {
                pt.datePart = this.vis.dataSettings.date_format.parse(pt.datePart);
            },
            this);

        // We use "nest" to transform it into d3-style dictionary, with key: workspaceId, values: data rows having workspaceId.
        var event_counts_by_workspace_id = d3.nest()
            .key(function(d) {
                return d.workspaceId;
            });

        // Entities in the visualization:
        var chart = this.vis.entities.chart,
            tooltip = this.vis.entities.tooltip,
            canvas = this.vis.canvas;

        // Set up scaling functions and the axes
        var xScale  = d3.time.scale().range([0, chart.properties.width]),
            yScale = d3.scale.linear().range([chart.properties.height, 0]);

        var xAxis = d3.svg.axis()
                .scale(xScale)
                .orient("bottom")
                .ticks(d3.time.weeks),
            yAxis = d3.svg.axis()
                .scale(yScale)
                .orient("left")
                .ticks(4);

        // Our chart will contain a "stack layout": https://github.com/mbostock/d3/wiki/Stack-Layout
        var stackLayout = d3.layout.stack()
            .offset("zero")
            .values(function(d) { return d.values; })
            // Date on x-axis
            .x(function(d) { return d.datePart; })
            // Count on y-axis
            .y(function(d) { return d.eventCount; });
        var layers = stackLayout(event_counts_by_workspace_id.entries(data));

        // Function yielding the areas to fill in
        var areaFcn = d3.svg.area()
            .interpolate("cardinal")
            .x(function(d) {
                return xScale(d.datePart);
            })
            .y0(function(d) {
                return yScale(d.y0);
            })
            .y1(function(d) {
                return yScale(d.y0 + d.y);
            });
        xScale.domain(d3.extent(data, function(d) { return d.datePart; }));
        yScale.domain([0, d3.max(data, function(d) { return d.y0 + d.y; })]);

        //// Rendering:
        // Attach dom elements for entities
        // and fix canvas dimensions to the chart size
        var $el = this.$(".chart");
        $el.html("").addClass("visualization");
        chart.domElement = $el;
        tooltip.domElememt = this.$(".tooltip");

        canvas = d3.select($el[0])
            .append("svg")
            .attr("width", chart.properties.width + chart.properties.margin.left + chart.properties.margin.right)
            .attr("height", chart.properties.height + chart.properties.margin.top + chart.properties.margin.bottom)
            .append("g")
            .attr("transform", "translate(" + chart.properties.margin.left + "," + chart.properties.margin.top + ")");

        canvas.selectAll(".layer")
            .data(layers)
            .enter()
            .append("path")
            .attr("class", "layer")
            .attr("d", function(d) {
                return areaFcn(d.values);
            })
            .style("fill", function(d, i) {
                return chart.properties.fillColors(i);
            })
            .on('mouseover', _.bind(this.mouseover, this))
            .on('mouseout', _.bind(this.mouseout, this));

        canvas.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + chart.properties.height + ")")
            .call(xAxis);

        canvas.append("g")
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
        chorus.isDevMode() && chorus.toast("=> " + type + ": " + msg, { skipTranslation: true });
    }
});
