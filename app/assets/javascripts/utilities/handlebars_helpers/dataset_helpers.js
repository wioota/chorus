chorus.handlebarsHelpers.dataset = {
    chooserMenu: function(choices, options) {
        options = options.hash;
        var max = options.max || 20;
        choices = choices || _.range(1, max + 1);
        options.initial = options.initial || _.last(choices);
        var selected = options.initial || choices[0];
        var translationKey = options.translationKey || "dataset.visualization.sidebar.category_limit";
        var className = options.className || '';
        var markup = "<div class='limiter " + className + "'><span class='pointing_l'></span>" + t(translationKey) + " &nbsp;<a href='#'><span class='selected_value'>" + selected + "</span><span class='triangle'></span></a><div class='limiter_menu_container'><ul class='limiter_menu " + className + "'>";
        _.each(choices, function(thing) {
            markup = markup + '<li>' + thing + '</li>';
        });
        markup = markup + '</ul></div></div>';
        return new Handlebars.SafeString(markup);
    },

    sqlDefinition: function(definition) {
        if (!definition) {
            return '';
        }
        definition || (definition = '');
        var promptSpan = $('<span>').addClass('sql_prompt').text(t("dataset.content_details.sql_prompt")).outerHtml();
        var sqlSpan = $('<span>').addClass('sql_content').attr('title', definition).text(definition).outerHtml();
        return new Handlebars.SafeString(t("dataset.content_details.definition", {sql_prompt: promptSpan, sql: sqlSpan}));
    },

    datasetLocation: function(databaseObject, label) {
        label = _.isString(label) ? label : "dataset.from";
        if (!databaseObject.schema()) return "";
        var dataSource = databaseObject.dataSource();
        var schema = databaseObject.schema();
        var database = databaseObject.database();

        var schemaPieces = [];
        var dataSourceName = dataSource.name();
        var databaseName = (database && Handlebars.helpers.withSearchResults(database).name()) || "";
        var schemaName = Handlebars.helpers.withSearchResults(schema).name();

        if (databaseObject.get('hasCredentials') === false) {
            schemaPieces.push(dataSourceName);
            if (databaseName.toString()) {
                schemaPieces.push(databaseName);
            }
            schemaPieces.push(schemaName);
        } else {
            schemaPieces.push(Handlebars.helpers.linkTo(dataSource.showUrl(), dataSourceName, {"class": "data_source"}).toString());
            if (databaseName.toString()) {
                schemaPieces.push(Handlebars.helpers.linkTo(database.showUrl(), databaseName, {"class": "database"}).toString());
            }
            schemaPieces.push(Handlebars.helpers.linkTo(schema.showUrl(), schemaName, {'class': 'schema'}).toString());
        }
        return new Handlebars.SafeString($("<span></span>").html(t(label, {location: schemaPieces.join('.')})).outerHtml());
    },

    humanizedDatasetType: function(dataset, statistics) {
        if (!dataset) { return ""; }
        var keys = ["dataset.entitySubtypes", dataset.entitySubtype];
        if (statistics instanceof chorus.models.DatasetStatistics && statistics.get("objectType")) {
            keys.push(statistics.get("objectType"));
        }
        else if (dataset.entitySubtype === "CHORUS_VIEW" || dataset.entitySubtype === "SOURCE_TABLE")
        {
            keys.push(dataset.objectType);
        }
        else {
            return t("loading");
        }
        var key = keys.join(".");
        return t(key);
    },

    importFrequencyTag: function(frequency) {
        if (!frequency) {
            return '';
        }
        var result = '<span class="tag import_frequency">' +
            '<span class="arrow_left"></span><span class="tag_name">' + Handlebars.Utils.escapeExpression(frequency) + '</span>' +
            '</span>';
        return new Handlebars.SafeString(result);
    },

    importFrequencyForModel: function(model) {
        return model.importFrequency &&
            model.importFrequency() &&
            t("import.frequency." + model.importFrequency().toLowerCase());
    }
};

_.each(chorus.handlebarsHelpers.dataset, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});
