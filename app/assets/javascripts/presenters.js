chorus.presenters.Base = function(model, options) {
    this.resource = this.model = model;
    this.options = options || {};

    this.setup && this.setup();

    this.workFlowsEnabled = function() {
        return chorus.models.Config.instance().get("workFlowConfigured");
    };
};

chorus.presenters.Base.extend = chorus.classExtend;

