chorus.views.CheckableList = chorus.views.SelectableList.extend({
    additionalClass: "selectable list",
    templateName: "empty",

    events: {
        "click  li input[type=checkbox]": "checkboxClicked",
        "change li input[type=checkbox]": "checkboxChanged"
    },

    setup: function() {
        this.eventName = this.options.entityType;
        this.entityViewType = this.options.entityViewType;
        this.listItemOptions = this.options.listItemOptions || {};

        if (this.options.entityType) {
            this.selectedModels = this.options.selectedModels || this.collection.clone().reset();
        } else {
            this.selectedModels = this.options.selectedModels || new chorus.collections.Base();
        }

        this.subscribePageEvent("selectAll", this.selectAll);
        this.subscribePageEvent("selectNone", this.selectNone);
        this.subscribePageEvent("checked", this.refreshCheckboxesFromSelectedModels);

        this._super("setup", arguments);
    },


    postRender: function() {
        _.each(this.liViews, function(liViews) {
            liViews.teardown();
        });
        this.liViews = [];
        this.collection.each(function(model) {
            var view = this.makeListItemView(model);
            $(this.el).append(view.render().el);
            this.liViews.push(view);
            this.registerSubView(view);
        }, this);

        this._super('postRender', arguments);

        this.checkSelectedModels();
    },

    checkSelectedModels: function() {
        var checkboxes = this.$("input[type=checkbox]");
        this.collection.each(function(model, i) {
            if (this.selectedModels.get(model.id)) {
                checkboxes.eq(i).prop("checked", true);
            }
        }, this);
    },

    checkboxClicked: function(e) {
        e.stopPropagation();
    },

    checkboxChanged: function(e) {
        var clickedBox = $(e.currentTarget);
        var clickedLi = $(e.currentTarget.parentElement);
        var index = this.$("> li input[type=checkbox]").index(clickedBox);
        var isChecked = clickedBox.prop("checked");
        var model = this.collection.at(index);

        if (isChecked) {
            if (!this.findSelectedModel(model)) {
                this.selectedModels.add(model);
            }
        } else {
            var match = this.findSelectedModel(model);
            this.selectedModels.remove(match);
        }

        chorus.PageEvents.broadcast("checked", this.selectedModels);
        chorus.PageEvents.broadcast(this.eventName+":checked", this.selectedModels);
    },

    findSelectedModel: function(model) {
        return this.selectedModels.findWhere({
            entityType: model.get('entityType'),
            id: model.get('id')
        });
    },
    
    refreshCheckboxesFromSelectedModels: function(models) {
        _.each(this.liViews, _.bind(function(li, index) {
            var model = this.collection.at(index);
            if (this.findSelectedModel(model)) {
                li.$el.addClass("checked");
                li.$('input[type=checkbox]').prop("checked", true);
            } else {
                li.$el.removeClass("checked");
                li.$('input[type=checkbox]').prop("checked", false);
            }
        }, this));
    },

    selectAll: function() {
        this.selectedModels.reset(this.collection.models);
        chorus.PageEvents.broadcast("checked", this.selectedModels);
        chorus.PageEvents.broadcast(this.eventName + ":checked", this.selectedModels);
    },

    selectNone: function() {
        this.selectedModels.reset();
        chorus.PageEvents.broadcast("checked", this.selectedModels);
        chorus.PageEvents.broadcast(this.eventName + ":checked", this.selectedModels);
    },

    makeListItemView: function(model) {
        return new this.entityViewType(_.extend({model: model, checkable: true}, this.listItemOptions));
    }
});