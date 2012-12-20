(function() {
    var TextExtAjax = $.fn.textext.TextExtAjax;

    TextExtAjax.prototype.onComplete = function(data, query)
    {
        var self   = this,
            result = data.response;

        self.dontShowLoading();

        result = _.reject(result, function(tag) {
            return self.opts('ajax.existingTagCollection').containsTag(tag.name);
        });

        self.trigger('setSuggestions', { result : result });
    };
})();
