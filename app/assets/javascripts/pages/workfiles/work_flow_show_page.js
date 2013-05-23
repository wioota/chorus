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
        window.addEventListener('message', _.bind(this.respondToIframe, this));
    },

    context: function() {
        return {
            alpineUrl: this.model.loaded ? this.model.iframeUrl() : ""
        };
    },

    respondToIframe: function(event) {
        if(event.data === 'unauthorized') {
            chorus.requireLogin();
        }
    }
});
