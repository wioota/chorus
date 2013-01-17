//= require ./workfile
chorus.models.AlpineWorkfile = chorus.models.Workfile.extend({
    iconUrl: function(options) {
        return chorus.urlHelpers.fileIconUrl('afm', options && options.size);
    }
});