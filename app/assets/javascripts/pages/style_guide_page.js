chorus.pages.StyleGuidePage = chorus.pages.Base.extend({
    setup: function() {
        this.mainContent = new chorus.views.MainContentView({
            content: new chorus.views.StaticTemplate("style_guide"),
            contentHeader: new chorus.views.StaticTemplate("default_content_header", {title: 'Style Guide Page'}),
            contentDetails: new chorus.views.StaticTemplate("plain_text", {text: 'Design rules for a happy family.'})
        });

        //sidebar is optional
        this.sidebar = new chorus.views.StaticTemplate("plain_text", {text: "sidebar is 250px wide"});

        //subnavs require a workspace and are optional
        this.workspace = new chorus.models.Workspace({ description: "One awesome workspace"});
        this.workspace.loaded = true;
        this.subNav = new chorus.views.SubNav({model: this.workspace, tab: "workfiles"});

    },

    postRender: function() {
        this.siteElements = new chorus.pages.StyleGuidePage.SiteElementsView();
        $(this.el).append(this.siteElements.render().el);
    }
});

chorus.pages.StyleGuidePage.SiteElementsView = Backbone.View.extend({
    tagName: "ul",
    className: "views",

    buildModels: function() {
        var models = {};
        var tagList = (function(length) {
            var tags = [];
            for(var i = 0; i < length; i++) {
                tags.push({name: "Tag Numba " + i});
            }
            return tags;
        })(50);

        models.workspace = new chorus.models.Workspace({
            name: "Some Workspace",
            summary: "One awesome workspace",
            owner: {firstName: "Bob", lastName: "Lablaw"},
            "public": true,
            archivedAt: null,
            tags: tagList,
            completeJson: true
        });
        models.workspace._sandbox = new chorus.models.Sandbox({database: {id: 1, instance: {id: 1, name: 'Data Source'}}});

        models.privateWorkspace = new chorus.models.Workspace({ name: "Private Workspace", summary: "Lots of secrets here", owner: {firstName: "Not", lastName: "You"}, "public": false, archivedAt: null});
        models.privateWorkspace.loaded = true;

        models.archivedWorkspace = new chorus.models.Workspace({
            name: "Archived Workspace",
            summary: "old data",
            owner: {firstName: "The", lastName: "Past"},
            "public": false,
            archiver: {firstName: "Mr", lastName: "Archiver"},
            archivedAt: "1985-07-21T06:21:02Z"});
        models.archivedWorkspace.loaded = true;

        models.instanceAccount = new chorus.models.InstanceAccount();

        models.subNav = new chorus.views.SubNav({model: models.workspace, tab: "workfiles"});

        models.tag = new chorus.models.Tag({
            name: "my first tag",
            count: 20
        });

        models.greenplumDataSource = new chorus.models.GpdbDataSource({
            name: "Greenplum Data Source",
            online: true,
            description: "This is a description of a data source. It is so sick, so AWESOME!",
            tags: tagList,
            completeJson: true
        });

        models.oracleDataSource = new chorus.models.OracleDataSource({
            name: "Oracle Data Source",
            online: false,
            tags: tagList,
            completeJson: true
        });

        models.hdfsDataSource = new chorus.models.HdfsDataSource({
            name: "Angry Elephant",
            online: true,
            tags: tagList,
            completeJson: true
        });

        models.gnipDataSource = new chorus.models.GnipDataSource({
            name: "Some Gnip Source",
            online: true,
            entityType: "gnip_data_source",
            tags: tagList,
            completeJson: true
        });

        models.database = new chorus.models.Database({
            "name": "Some database",
            "instance": models.greenplumDataSource
        });

        models.otherDatabase = new chorus.models.Database({
            "name": "Another database",
            "instance": models.greenplumDataSource
        });

        models.schema = new chorus.models.Schema({
            "name": "Some schema",
            "database": models.database,
            "datasetCount": 3,
            "refreshedAt": true
        });

        models.otherSchema = new chorus.models.Schema({
            "name": "Other schema",
            "database": models.database,
            refreshedAt: null
        });

        models.dataset = new chorus.models.Dataset({
            type: "SOURCE_TABLE",
            objectName: "table",
            schema: models.schema,
            entityType: "dataset",
            objectType: "TABLE",
            tags: tagList,
            associatedWorkspaces: [
                models.workspace
            ],
            completeJson: true
        });

        models.datasetImportability = new chorus.models.DatasetImportability({
            "importable": "false",
            "invalidColumns": []
        });

        models.otherDataset = new chorus.models.Dataset({
            "type": "SOURCE_TABLE",
            "objectName": "other table",
            "schema": models.schema,
            "tags": [
                models.tag
            ],
            "entityType": "dataset",
            "objectType": "TABLE"
        });

        models.workfile = new chorus.models.Workfile({
            fileName: "Some workfile",
            tags: tagList,
            completeJson: true,
            workspace: models.workspace
        });

        models.otherWorkfile = new chorus.models.Workfile({
            fileName: "Bestest Tableaust Workfile",
            fileType: "tableau_workbook",
            workbookName: "hey tableau is the bomb",
            workbookUrl: "http://10.80.129.44/workbooks/hey tableau is the bomb",
            completeJson: true
        });

        models.task = (function() {
            var animals = ['aardvark', 'bat', 'cheetah'];
            var columns = [
                { name: "id" },
                { name: "value" },
                { name: "animal" }
            ];
            var rows = _.map(_.range(50), function(i) {
                return {
                    id: i,
                    value: Math.round(100 * Math.random(), 0),
                    animal: _.shuffle(animals)[0]
                };
            });

            return new chorus.models.WorkfileExecutionTask({
                columns: columns,
                rows: rows
            });
        })();

        models.user = new chorus.models.User({ username: "edcadmin",
            firstName: "Johnny",
            lastName: "Danger",
            admin: false,
            id: "InitialUser1",
            image: { icon: "/images/default-user-icon.png"},
            tags: tagList,
            title: "Chief Data Scientist",
            email: "searchquery@jacobibeier.com",
            dept: "Corporation Corp., Inc.",
            notes: "One of our top performers",
            completeJson: true});
        models.otherUser = new chorus.models.User({ username: "edcadmin", firstName: "Laurie", lastName: "Blakenship", admin: true, id: "InitialUser2", image: { icon: "/images/default-user-icon.png"}});
        models.thirdUser = new chorus.models.User({ username: "edcadmin", firstName: "George", lastName: "Gorilla", admin: false, id: "InitialUser3", image: { icon: "/images/default-user-icon.png"}});

        models.hdfsFile = new chorus.models.HdfsEntry({"name": "foo.cpp", isDir: false, hdfsDataSource: models.hdfsDataSource, contents: ["a,b,1", "b,c,2", "d,e,3"], tags: tagList, size: 1024, completeJson: true});
        models.hdfsDir = new chorus.models.HdfsEntry({name: "TestExpression", path: '/arbitrary/path', isDir: true, hdfsDataSource: models.hdfsDataSource, tags: tagList, count: 4, completeJson: true});

        models.activity = new chorus.models.Activity({
            "action": "DataSourceChangedOwner",
            "actor": models.user,
            "dataSource": models.greenplumDataSource,
            "newOwner": models.otherUser,
            "timestamp": "2013-01-31T20:14:27Z"
        });

        models.otherActivity = new chorus.models.Activity({
            "action": "WorkfileCreated",
            "actor": models.user,
            "workfile": models.workfile,
            "commitMessage": "I am committed to this workfile",
            "workspace": models.workspace,
            "timestamp": "2013-01-31T20:14:27Z"
        });

        models.searchResult = new chorus.models.SearchResult({
            users: {
                results: [models.user.set({ highlightedAttributes: {
                    "lastName": [
                        "<em>Danger</em>"
                    ]
                }})],
                numFound: 14
            },

            workspaces: {
                results: [
                    models.workspace.set({ highlightedAttributes: { summary: ["<em>Danger</em> Zone!!"]}}),
                    models.archivedWorkspace.set({highlightedAttributes: { summary: ['<em>Search Hit</em>']}})
                    ],
                numFound: 1
            },

            hdfsEntries: {
                results: [models.hdfsFile],
                numFound: 1
            },

            datasets: {
                results: [models.dataset],
                numFound: 1000
            },

            workfiles: {
                results: [models.workfile],
                numFound: 2
            },

            instances: {
                results: [models.greenplumDataSource, models.hdfsDataSource, models.gnipDataSource],
                numFound: 4
            },

            otherFiles: {
                results: [{
                        "id": 1000009,
                        "name": "searchquery_hadoop",
                        "entityType": "attachment",
                        "type": "",
                        "instance": {
                            "name": "searchquery_hadoop",
                            "host": "hadoop.example.com",
                            "port": 1111,
                            "id": 1000000,
                            "description": "searchquery for the hadoop data source",
                            "entityType": "hdfs_data_source"
                        },
                        "completeJson": true,
                        "highlightedAttributes": {
                            "name": [
                                "<em>searchquery</em>_<em>hadoop</em>"
                            ]
                        }
                    }
                ],
                numFound: 7
            }
        });

        models.chorusView = new chorus.models.ChorusView(models.dataset.set({query: "SELECT * FROM everywhere;"}));

        chorus.session._user = new chorus.models.User({apiKey: "some-api-key"});

        return models;
    },

    buildCollections: function(models) {
        var collections = {};

        collections.tagSet = new chorus.collections.TagSet([models.tag, new chorus.models.Tag({name: 'Another Taggy TagTag', count: 10})]);
        collections.tagSet.loaded = true;

        collections.workspaceSet = new chorus.collections.WorkspaceSet([models.workspace, models.privateWorkspace, models.archivedWorkspace]);
        collections.workspaceSet.loaded = true;

        collections.datasetSet = new chorus.collections.SchemaDatasetSet([models.dataset, models.otherDataset], {schemaId: models.schema.get("id")});
        collections.datasetSet.loaded = true;

        collections.databaseSet = new chorus.collections.DatabaseSet([models.database, models.otherDatabase]);
        collections.databaseSet.loaded = true;

        collections.schemaSet = new chorus.collections.SchemaSet([models.schema, models.otherSchema]);
        collections.schemaSet.loaded = true;

        collections.dataSourceSet = new chorus.collections.DataSourceSet([models.oracleDataSource, models.greenplumDataSource]);
        collections.hdfsDataSourceSet = new chorus.collections.HdfsDataSourceSet([models.hdfsDataSource]);
        collections.gnipDataSourceSet = new chorus.collections.GnipDataSourceSet([models.gnipDataSource]);
        collections.dataSourceSet.loaded = collections.hdfsDataSourceSet.loaded = collections.gnipDataSourceSet.loaded = true;

        collections.workfileSet = new chorus.collections.WorkfileSet([models.workfile, models.otherWorkfile]);
        collections.workfileSet.loaded = true;

        collections.loadingCollection = new chorus.collections.UserSet();
        collections.userCollection = new chorus.collections.UserSet([models.user, models.otherUser, models.thirdUser]);
        collections.userCollection.loaded = true;

        collections.CsvHdfsFileSet = new chorus.collections.CsvHdfsFileSet([models.hdfsFile], {hdfsDataSource: models.hdfsDataSource});

        collections.hdfsEntrySet = new chorus.collections.HdfsEntrySet([models.hdfsFile, models.hdfsDir], {
            path: '/data/somewhere',
            hdfsDataSource: {id: 222},
            id: 11
        });
        collections.hdfsEntrySet.loaded = true;

        collections.activitySet = new chorus.collections.ActivitySet([models.activity, models.otherActivity]);
        collections.activitySet.loaded = true;

        return collections;
    },

    buildViews: function(models, collections) {
        return {
            "Breadcrumbs": new chorus.views.BreadcrumbsView({
                breadcrumbs: [
                    { label: t("breadcrumbs.home"), url: "#/" },
                    { label: t("breadcrumbs.users"), url: "#/users" },
                    { label: t("breadcrumbs.new_user") }
                ]
            }),

            "Sub Nav": new chorus.views.SubNav({model: models.workspace, tab: "summary"}),

            "Link Menu": new chorus.views.LinkMenu({title: "Link Menu", options: [
                {data: "first", text: "Text of first option"},
                {data: "second", text: "Text of second option"}
            ]}),

            "Basic Main Content View": new chorus.views.MainContentView({
                contentHeader: new chorus.views.StaticTemplate("default_content_header", {title: 'Content Header'}),
                contentDetails: new chorus.views.StaticTemplate("plain_text", {text: 'Content Details'}),
                content: new chorus.views.StaticTemplate("ipsum")
            }),

            "Font Styles": new chorus.views.StyleGuideFonts(),

            "Data Table": new chorus.views.TaskDataTable({
                model: new chorus.models.WorkfileExecutionTask({ result: {
                    columns: [
                        { name: "id" },
                        { name: "city" },
                        { name: "state" },
                        { name: "zip" },
                        { name: "other_state" },
                        { name: "other_zip" }
                    ],
                    rows: [
                        { id: 1, city: "Oakland", state: "CA", zip: "94612", other_state: "CA", other_zip: "94612" },
                        { id: 2, city: "Arcata", state: "CA", zip: "95521", other_state: "CA", other_zip: "95521" },
                        { id: 3, city: "Lafayette", state: "IN", zip: "47909", other_state: "IN", other_zip: "47909" },
                        { id: 1, city: "Oakland", state: "CA", zip: "94612", other_state: "CA", other_zip: "94612" },
                        { id: 2, city: "Arcata", state: "CA", zip: "95521", other_state: "CA", other_zip: "95521" },
                        { id: 3, city: "Lafayette", state: "IN", zip: "47909", other_state: "IN", other_zip: "47909" },
                        { id: 1, city: "Oakland", state: "CA", zip: "94612", other_state: "CA", other_zip: "94612" },
                        { id: 2, city: "Arcata", state: "CA", zip: "95521", other_state: "CA", other_zip: "95521" },
                        { id: 3, city: "Lafayette", state: "IN", zip: "47909", other_state: "IN", other_zip: "47909" },
                        { id: 1, city: "Oakland", state: "CA", zip: "94612", other_state: "CA", other_zip: "94612" },
                        { id: 2, city: "Arcata", state: "CA", zip: "95521", other_state: "CA", other_zip: "95521" },
                        { id: 3, city: "Lafayette", state: "IN", zip: "47909", other_state: "IN", other_zip: "47909" },
                        { id: 1, city: "Oakland", state: "CA", zip: "94612", other_state: "CA", other_zip: "94612" },
                        { id: 2, city: "Arcata", state: "CA", zip: "95521", other_state: "CA", other_zip: "95521" },
                        { id: 3, city: "Lafayette", state: "IN", zip: "47909", other_state: "IN", other_zip: "47909" },
                        { id: 1, city: "Oakland", state: "CA", zip: "94612", other_state: "CA", other_zip: "94612" },
                        { id: 2, city: "Arcata", state: "CA", zip: "95521", other_state: "CA", other_zip: "95521" },
                        { id: 3, city: "Lafayette", state: "IN", zip: "47909", other_state: "IN", other_zip: "47909" },
                        { id: 1, city: "Oakland", state: "CA", zip: "94612", other_state: "CA", other_zip: "94612" },
                        { id: 2, city: "Arcata", state: "CA", zip: "95521", other_state: "CA", other_zip: "95521" },
                        { id: 3, city: "Lafayette", state: "IN", zip: "47909", other_state: "IN", other_zip: "47909" }
                    ]
                }})
            }),

            "Visualization: BoxPlot": new chorus.views.visualizations.Boxplot({
                model: new chorus.models.BoxplotTask({
                    xAxis: "test_coverage",
                    yAxis: "speed",
                    columns: [
                        { name: "bucket", typeCategory: "STRING" },
                        { name: "min", typeCategory: "REAL_NUMBER" },
                        { name: "median", typeCategory: "REAL_NUMBER" },
                        { name: "max", typeCategory: "REAL_NUMBER" },
                        { name: "firstQuartile", typeCategory: "REAL_NUMBER" },
                        { name: "thirdQuartile", typeCategory: "REAL_NUMBER" },
                        { name: "percentage", typeCategory: "STRING" }
                    ],
                    rows: [
                        { bucket: 'january', min: 1, firstQuartile: 5, median: 8, thirdQuartile: 12, max: 25, percentage: "20.999%" },
                        { bucket: 'february', min: 2, firstQuartile: 3, median: 5, thirdQuartile: 7, max: 8, percentage: "40.3%" },
                        { bucket: 'march', min: 10, firstQuartile: 10, median: 25, thirdQuartile: 30, max: 35, percentage: "10.12" },
                        { bucket: 'april', min: 2, firstQuartile: 3, median: 8, thirdQuartile: 9, max: 15, percentage: "30%" }
                    ],
                    dataset: models.dataset
                }),
                x: 'animal',
                y: 'value'
            }),

            "Visualization: Frequency Plot": new chorus.views.visualizations.Frequency({
                model: new chorus.models.FrequencyTask({
                    columns: [
                        {name: "bucket", typeCategory: "STRING"},
                        {name: "count", typeCategory: "WHOLE_NUMBER"}
                    ],

                    rows: [
                        { bucket: "Twenty", count: 20 },
                        { bucket: "Eight", count: 8 },
                        { bucket: "Five", count: 5 },
                        { bucket: "One", count: 1 },
                        { bucket: "Zero", count: 0 }
                    ],
                    "chart[yAxis]": "Custom y Axis Title",
                    dataset: models.dataset
                })
            }),

            "Visualization: HistogramPlot": new chorus.views.visualizations.Histogram({
                model: new chorus.models.HistogramTask({
                    columns: [
                        {name: "bin", typeCategory: "STRING"},
                        {name: "frequency", typeCategory: "WHOLE_NUMBER"}
                    ],

                    rows: [
                        { bin: [0, 2], frequency: 5 },
                        { bin: [2, 4], frequency: 8 },
                        { bin: [4, 6], frequency: 0 },
                        { bin: [6, 8], frequency: 1 },
                        { bin: [8, 10], frequency: 20 }
                    ],
                    "chart[xAxis]": "Custom x Axis Title",
                    dataset: models.dataset
                })
            }),

            "Visualization: Heatmap": new chorus.views.visualizations.Heatmap({
                model: new chorus.models.HistogramTask({
                    xAxis: "brutality",
                    yAxis: "victory_points",
                    columns: [
                        { "name": "x", "typeCategory": "WHOLE_NUMBER" },
                        { "name": "y", "typeCategory": "WHOLE_NUMBER" },
                        { "name": "value", "typeCategory": "REAL_NUMBER" },
                        { "name": "xLabel", "typeCategory": "STRING" },
                        { "name": "yLabel", "typeCategory": "STRING" }
                    ],

                    rows: [
                        {yLabel: [30, 64.83], xLabel: [200001, 366667.5], value: 27952, y: 1, x: 1},
                        {yLabel: [64.83, 99.67], xLabel: [200001, 366667.5], value: 27719, y: 2, x: 1},
                        {yLabel: [99.67, 134.5], xLabel: [200001, 366667.5], value: 27714, y: 3, x: 1},
                        {yLabel: [134.5, 169.33], xLabel: [200001, 366667.5], value: 27523, y: 4, x: 1},
                        {yLabel: [169.33, 204.17], xLabel: [366667.5, 533334], value: 27926, y: 5, x: 2},
                        {yLabel: [204.17, 239], xLabel: [366667.5, 533334], value: 27738, y: 6, x: 2},
                        {yLabel: [30, 64.83], xLabel: [533334, 700000.5], value: 27801, y: 1, x: 3},
                        {yLabel: [64.83, 99.67], xLabel: [533334, 700000.5], value: 27675, y: 2, x: 3},
                        {yLabel: [99.67, 134.5], xLabel: [533334, 700000.5], value: 27936, y: 3, x: 3},
                        {yLabel: [134.5, 169.33], xLabel: [533334, 700000.5], value: 27558, y: 4, x: 3},
                        {yLabel: [169.33, 204.17], xLabel: [533334, 700000.5], value: 27953, y: 5, x: 3},
                        {yLabel: [204.17, 239], xLabel: [533334, 700000.5], value: 27743, y: 6, x: 3},
                        {yLabel: [30, 64.83], xLabel: [700000.5, 866667], value: 27635, y: 1, x: 4},
                        {yLabel: [64.83, 99.67], xLabel: [700000.5, 866667], value: 27964, y: 2, x: 4},
                        {yLabel: [99.67, 134.5], xLabel: [700000.5, 866667], value: 27528, y: 3, x: 4},
                        {yLabel: [134.5, 169.33], xLabel: [700000.5, 866667], value: 28089, y: 4, x: 4},
                        {yLabel: [169.33, 204.17], xLabel: [700000.5, 866667], value: 27673, y: 5, x: 4},
                        {yLabel: [204.17, 239], xLabel: [700000.5, 866667], value: 27777, y: 6, x: 4},
                        {yLabel: [30, 64.83], xLabel: [866667, 1033333.5], value: 27722, y: 1, x: 5},
                        {yLabel: [64.83, 99.67], xLabel: [866667, 1033333.5], value: 28019, y: 2, x: 5},
                        {yLabel: [99.67, 134.5], xLabel: [866667, 1033333.5], value: 27608, y: 3, x: 5},
                        {yLabel: [134.5, 169.33], xLabel: [866667, 1033333.5], value: 27812, y: 4, x: 5},
                        {yLabel: [169.33, 204.17], xLabel: [866667, 1033333.5], value: 27742, y: 5, x: 5},
                        {yLabel: [204.17, 239], xLabel: [866667, 1033333.5], value: 27764, y: 6, x: 5},
                        {yLabel: [30, 64.83], xLabel: [1033333.5, 1200000], value: 27818, y: 1, x: 6},
                        {yLabel: [64.83, 99.67], xLabel: [1033333.5, 1200000], value: 27778, y: 2, x: 6},
                        {yLabel: [99.67, 134.5], xLabel: [1033333.5, 1200000], value: 27662, y: 3, x: 6},
                        {yLabel: [134.5, 169.33], xLabel: [1033333.5, 1200000], value: 27888, y: 4, x: 6},
                        {yLabel: [169.33, 204.17], xLabel: [1033333.5, 1200000], value: 27951, y: 5, x: 6},
                        {yLabel: [204.17, 239], xLabel: [1033333.5, 1200000], value: 26807, y: 6, x: 6}
                    ],
                    dataset: models.dataset
                })
            }),

            "Visualization: Timeseries": new chorus.views.visualizations.Timeseries({
                model: new chorus.models.TimeseriesTask({
                    columns: [
                        {name: "time", typeCategory: "DATE"},
                        {name: "value", typeCategory: "WHOLE_NUMBER"}
                    ],

                    rows: [
                        { time: '2010-01-01', value: 321 },
                        { time: '2010-02-01', value: 124 },
                        { time: '2011-03-01', value: 321 },
                        { time: '2011-04-01', value: 321 },
                        { time: '2011-05-01', value: 421 },
                        { time: '2012-06-01', value: 621 },
                        { time: '2012-07-01', value: 524 },
                        { time: '2012-08-01', value: 824 },
                        { time: '2012-09-01', value: 924 },
                        { time: '2012-09-02', value: 926 },
                        { time: '2012-09-03', value: 927 },
                        { time: '2012-09-04', value: 124 },
                        { time: '2012-09-05', value: 224 },
                        { time: '2012-09-06', value: 924 },
                        { time: '2012-09-07', value: 524 },
                        { time: '2012-09-08', value: 924 },
                        { time: '2012-10-01', value: 724 }
                    ],
                    xAxis: "Day of the Week",
                    yAxis: "Parties",
                    timeType: "date",
                    dataset: models.dataset
                })
            }),

            "Color Palette": new chorus.views.ColorPaletteView(),

            "List Page (loading)": new chorus.views.MainContentList({
                modelClass: "Dataset",
                collection: collections.loadingCollection}),

            "User List": new chorus.views.MainContentList({
                modelClass: "User",
                collection: collections.userCollection,
                linkMenus: {
                    sort: {
                        title: t("users.header.menu.sort.title"),
                        options: [
                            {data: "firstName", text: t("users.header.menu.sort.first_name")},
                            {data: "lastName", text: t("users.header.menu.sort.last_name")}
                        ],
                        event: "sort",
                        chosen: "lastName"
                    }
                },
                buttons: [
                    {
                        url: "#/users/new",
                        text: "Create Thing"
                    },
                    {
                        url: "#/users/new",
                        text: "Create Other Thing"
                    }
                ]
            }),

            "Database List": new chorus.views.MainContentList({
                collection: collections.databaseSet,
                modelClass: "Database"
            }),

            "Workfile List": new chorus.views.MainContentList({
                collection: collections.workfileSet,
                modelClass: "Workfile"
            }),

            "Schema List": new chorus.views.MainContentList({
                collection: collections.schemaSet,
                modelClass: "Schema"
            }),

            "Workspace List": new chorus.views.MainContentList({
                collection: collections.workspaceSet,
                modelClass: "Workspace"
            }),

            "Tag List": new chorus.views.MainContentList({
                collection: collections.tagSet,
                modelClass: 'Tag'
            }),

            "HDFS Entry List": new chorus.views.MainContentList({
                collection: collections.hdfsEntrySet,
                modelClass: "HdfsEntry",
                useCustomList: true
            }),

            "Dataset List": new chorus.views.MainContentList({
                collection: collections.datasetSet,
                modelClass: "Dataset",
                useCustomList: true
            }),

            "Data Source List": (function() {
                var options = {
                    dataSources: collections.dataSourceSet,
                    hdfsDataSources: collections.hdfsDataSourceSet,
                    gnipDataSources: collections.gnipDataSourceSet
                };

                return new chorus.views.MainContentView({
                    contentDetails: new chorus.views.DataSourceIndexContentDetails(options),
                    content: new chorus.views.DataSourceList(options),
                    useCustomList: true
                });
            })(),


            "Search Result List": new chorus.views.SearchResults({
                model: models.searchResult
            }),

            "Activity List": new chorus.views.ActivityList({
                collection: collections.activitySet
            })

        };
    },

    buildDialogs: function(models, collections) {
        return {
            "Workspace Instance Account Dialog": new chorus.dialogs.WorkspaceInstanceAccount({model: models.instanceAccount, pageModel: models.workspace}),

            "Instance Account Dialog": new chorus.dialogs.InstanceAccount({
                title: t("instances.account.add.title"),
                instance: models.greenplumDataSource
            }),

            "Change Password Dialog": new chorus.dialogs.ChangePassword(),

            "Show API Key Dialog": new chorus.dialogs.ShowApiKey(),

            "New Note Dialog": new chorus.dialogs.NotesNew(),

            "Comment Dialog": new chorus.dialogs.Comment(),

            "Create Directory External Table from HDFS Dialog": new chorus.dialogs.CreateDirectoryExternalTableFromHdfs({
                collection: collections.CsvHdfsFileSet,
                directoryName: "some directory"
            }),

            "Edit Note Dialog": new chorus.dialogs.EditNote({
                activity: models.activity
            }),

            "Edit Tags Dialog": new chorus.dialogs.EditTags({
                collection: collections.workfileSet
            }),

            "Insights New Dialog": new chorus.dialogs.InsightsNew(),

            "Pick Workspace Dialog": new chorus.dialogs.PickWorkspace({collection: collections.workspaceSet}),

            "SQL Preview Dialog": new chorus.dialogs.SqlPreview({model: models.chorusView}),

            "Create Database View Dialog": new chorus.dialogs.CreateDatabaseView({ pageModel: models.dataset }),

            "Dataset Not Importable Alert": new chorus.alerts.DatasetNotImportable({ datasetImportability: models.datasetImportability })
        };
    },

    initialize: function() {
        _.defer(_.bind(this.render, this));

        var models = this.buildModels();
        var collections = this.buildCollections(models);

        this.views = this.buildViews(models, collections);
        this.dialogs = this.buildDialogs(models, collections);
    },

    renderViews: function(views) {
        var self = this;
        _.each(views, function(view, name) {
            $(self.el).append("<li class='view'><h1>" + name + "</h1><div class='view_guts'/></li>");
            view.setElement(self.$(".view_guts:last"));
            view.render();
        });
    },

    render: function() {
        $(this.el).empty();

        this.renderViews(this.views);
        this.renderViews(this.dialogs);

        setInterval(this.enableScrolling, 100);

        return this;
    },

    // Used to ensure scrolling works after re-rendering dialog
    enableScrolling: function() {
        $("body").css("overflow", "visible");
    }
});
