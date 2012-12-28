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

    $.fn.textext.TextExt.prototype.invalidateBounds = function() {
        this.trigger('preInvalidate');
        this.trigger('postInvalidate');
    };

    var TextExtTags = $.fn.textext.TextExtTags;

    TextExtTags.prototype.onPreInvalidate = $.noop;

    TextExtTags.prototype.addTags = function(tags)
    {
        if(!tags || tags.length === 0)
            return;

        var self      = this,
            core      = self.core(),
            container = self.containerElement(),
            i, tag
            ;

        for(i = 0; i < tags.length; i++)
        {
            tag = tags[i];

            if(tag && self.isTagAllowed(tag))
                container.append(self.renderTag(tag));
        }

        container.append(self.input().detach());

        self.updateFormCache();
        core.getFormData();
        core.invalidateBounds();
    };

    var TextExt = $.fn.textext.TextExt;

    TextExt.prototype.getFormData = function(keyCode) {
        var self = this,
            data = self.getWeightedEventResponse('getFormData', keyCode || 0)
            ;

        self.trigger('setFormData'  , data['form']);

        if (keyCode === 13 || keyCode === 108) {
            self.trigger('setInputData' , data['input']);
        }
    };
})();
