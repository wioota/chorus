chorus.pages.WorkFlowShowPage = chorus.pages.Base.extend({
    templateName: "header_iframe_layout",
    additionalClass: "logged_in_layout",
    pageClass: "full_height",

    makeModel: function(workfileId) {
        this.model = new chorus.models.AlpineWorkfile({id: workfileId});
        this.model.fetch();
    },

    setup: function() {
        this.listenTo(this.model, "loaded", this.render);
        this.boundIframeListener = _.bind(this.respondToIframe, this);
        window.addEventListener('message', this.boundIframeListener);
    },

    teardown: function() {
        this._super("teardown", arguments);
        window.removeEventListener('message', this.boundIframeListener);
    },

    context: function() {
        return {
            alpineUrl: this.model.loaded ? this.model.iframeUrl() : ""
        };
    },

    respondToIframe: function(event) {
        if(event.data.action === 'unauthorized') {
            chorus.requireLogin();
        } else if(event.data.action === 'go_to_workfile') {
            chorus.router.navigate(this.model.showUrl());
        }
    }
});
