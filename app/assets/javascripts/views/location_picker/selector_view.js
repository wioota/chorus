chorus.views.LocationPicker.SelectorView = chorus.views.Base.extend({

    onSelection: $.noop,
    onFetchFailed: $.noop,

    setState: function(stateValue) {
        this.stateValue = stateValue;
        this.restyle(stateValue);
        if (_.contains([this.STATES.UNAVAILABLE, this.STATES.LOADING, this.STATES.HIDDEN], stateValue)) {
            this.childPicker && this.childPicker.hide();
        }
    },

    hide: function() {
        this.setState(this.STATES.HIDDEN);
    },

    setSelection: function(model) {
        this.selection = model;
        this.onSelection();
    },

    postRender: function() {
        this.restyle(this.stateValue);
    },

    populateSelect: function(defaultValue) {
//        var models = (type === "dataSource") ? this.gpdbDataSources() : this[type + "s"].models;

        var select = this.rebuildEmptySelect();

        _.each(this.sortModels(this.collection && this.collection.models), function(model) {
            var option = $("<option/>")
                .prop("value", model.get("id"))
                .text(Handlebars.Utils.escapeExpression(model.get("name")));
            if(model.get("id") === defaultValue) {
                option.attr("selected", "selected");
            }
            select.append(option);
        });

        if(defaultValue !== undefined && !_.contains(_.pluck(this.collection.models, "id"), defaultValue)) {
//            if(type === "schema") this.showErrorForMissingSchema(); IMPLEMENT ME
            this.clearSelection();
        }

        chorus.styleSelect(select);
    },

    rebuildEmptySelect: function() {
        var select = this.$("select");
        select.html($("<option/>").prop('value', '').text(t("sandbox.select_one")));
        return select;
    },

    sortModels: function(models) {
        return _.clone(models).sort(function(a, b) {
            return naturalSort(a.get("name").toLowerCase(), b.get("name").toLowerCase());
        });
    },

    fetchFailed: function(collection) {
        this.onFetchFailed();
        this.trigger("error", collection);
        this.options.parent.trigger("error", collection);
    },

    restyle: function(state) {
        var section = this.$el;
        section.removeClass("hidden");
        section.find("a.new").removeClass("hidden");
        section.find(".loading_text, .select_container, .create_container, .unavailable").addClass("hidden");
        section.find(".create_container").removeClass("show_cancel_link");

        this.rebuildEmptySelect();

        switch(state) {
            case this.STATES.LOADING:
                section.find(".loading_text").removeClass("hidden");
                break;
            case this.STATES.SELECT:
                section.find(".select_container").removeClass("hidden");
                var currentSelection = this.selection;
                this.populateSelect(currentSelection && currentSelection.id);
                break;
            case this.STATES.CREATE_NEW:
                section.find(".create_container").removeClass("hidden");
                section.find(".create_container").addClass("show_cancel_link");
                section.find("a.new").addClass("hidden");
                break;
            case this.STATES.CREATE_NESTED:
                section.find(".create_container").removeClass("hidden");
                section.find("a.new").addClass("hidden");
                break;
            case this.STATES.UNAVAILABLE:
                section.find(".unavailable").removeClass("hidden");
                break;
            case this.STATES.HIDDEN:
                section.addClass("hidden");
                break;
        }
    },

    clearSelection: function() {
        delete this.selection;
        this.options.parent.triggerSchemaSelected();
    },

    STATES: {
        HIDDEN: 0,
        LOADING: 1,
        SELECT: 2,
        STATIC: 3,
        UNAVAILABLE: 4,
        CREATE_NEW: 5,
        CREATE_NESTED: 6
    }
});