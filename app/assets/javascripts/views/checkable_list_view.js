chorus.views.CheckableList = chorus.views.SelectableList.extend({
    additionalClass: "selectable list",

    events: {
        "click  li input[type=checkbox]": "checkboxClicked",
        "change li input[type=checkbox]": "checkboxChanged"
    },

    setup: function() {
        this.eventName = this.options.entityType;
        this.entityViewType = this.options.entityViewType;
        this.templateName = "empty";

        this.selectedModels = this.collection.clone();
        this.selectedModels.reset();
        this.selectedModels.attributes = this.collection.attributes;

        this.subscriptions.push(chorus.PageEvents.subscribe("selectAll", this.selectAll, this));
        this.subscriptions.push(chorus.PageEvents.subscribe("selectNone", this.selectNone, this));

        this._super("setup", arguments);
    },


    postRender: function() {
        _.each(this.liViews, function(liViews) {
            liViews.teardown();
        });
        this.liViews = [];
        this.collection.each(function(model) {
            var view = new this.entityViewType({model: model, checkable: true});
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

        clickedLi.toggleClass("checked", isChecked);

        if (isChecked) {
            if (!this.selectedModels.contains(model)) {
                this.selectedModels.add(model);
            }
        } else {
            this.selectedModels.remove(model);
        }

        chorus.PageEvents.broadcast(this.eventName+":checked", this.selectedModels);
    },

    selectAll: function() {
        this.$("> li input[type=checkbox]").prop("checked", true).change();
    },

    selectNone: function() {
        this.selectedModels.reset();
        this.$("> li input[type=checkbox]").prop("checked", false).change();
        chorus.PageEvents.broadcast(this.eventName + ":checked", this.selectedModels);
    }
});