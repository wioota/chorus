//= require ./item_wrapper_view

chorus.views.CheckableList = chorus.views.SelectableList.extend({
    constructorName: "CheckableListView",
    additionalClass: "selectable list",
    templateName: "empty",
    persistent: false,
    suppressRenderOnChange: true,

    events: {
        "click  li input[type=checkbox]": "checkboxClicked"
    },

    setup: function() {
        this.eventName = this.eventName || this.options.entityType;
        this.entityViewType = this.options.entityViewType;
        this.listItemOptions = this.options.listItemOptions || {};

        if(this.options.entityType) {
            this.selectedModels = this.options.selectedModels || this.collection.clone().reset();
        } else {
            this.selectedModels = this.options.selectedModels || new chorus.collections.Base();
        }

        this.subscribePageEvent("selectAll", this.selectAll);
        this.subscribePageEvent("selectNone", this.selectNone);
        this.subscribePageEvent("checked", this.checkSelectedModels);

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

        this.checkSelectedModels();

        this._super('postRender', arguments);
    },

    checkSelectedModels: function() {
        var liItems = this.$("li");
        this.collection.each(function(model, i) {
            var selected = !!this.selectedModels.get(model.id);
            liItems.eq(i).find("input[type=checkbox]").prop("checked", selected);
            liItems.eq(i).toggleClass("checked", selected);
        }, this);
    },

    addModelsToSelection: function(models) {
        this.selectedModels.add(_.filter(models, function (model) {
            return !this.findSelectedModel(model);
        }, this));
    },

    checkboxClicked: function(e) {
        e.stopPropagation();
        var clickedBox = $(e.currentTarget);
        var clickedLi = clickedBox.closest("li");
        var index = this.$("li").index(clickedLi);
        var model = this.collection.at(index);
        var willBeChecked = !this.findSelectedModel(model);

        if (willBeChecked) {
            var modelsToAdd = [model];
            if (e.shiftKey && this.previousIndex >= 0) {
                var min = _.min([this.previousIndex, index]);
                var max = _.max([this.previousIndex, index]);
                modelsToAdd = this.collection.models.slice(min, max + 1);
            }
            this.addModelsToSelection(modelsToAdd);
            this.previousIndex = index;
        } else {
            var match = this.findSelectedModel(model);
            this.selectedModels.remove(match);
            delete this.previousIndex;
        }

        chorus.PageEvents.broadcast("checked", this.selectedModels);
        chorus.PageEvents.broadcast(this.eventName + ":checked", this.selectedModels);
    },

    findSelectedModel: function(model) {
        return this.selectedModels.findWhere({
            entityType: model.get('entityType'),
            id: model.get('id')
        });
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
        var itemView = new this.entityViewType(_.extend({model: model, checkable: true}, this.listItemOptions));
        return new chorus.views.ItemWrapper({itemView: itemView});
    }
});
