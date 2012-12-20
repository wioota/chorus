(function() {
    var TextExtAjax = $.fn.textext.TextExtAjax;

    TextExtAjax.prototype.onComplete = function(data, query)
    {
        var self   = this,
            data = data.response,
            result = data
            ;

        self.dontShowLoading();

        // If results are expected to be cached, then we store the original
        // data set and return the filtered one based on the original query.
        // That means we do filtering on the client side, instead of the
        // server side.
        if(self.opts('ajax.cache.results') == true)
        {
            self._suggestions = data;
            result = self.itemManager().filter(data, query);
        }

        self.trigger('setSuggestions', { result : result });
    };

})();
