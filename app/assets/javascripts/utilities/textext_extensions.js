(function() {
    var TextExtAjax = $.fn.textext.TextExtAjax;
    var TextExtAutocomplete = $.fn.textext.TextExtAutocomplete;

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

    TextExtAutocomplete.prototype.onShowDropdown = function(e, renderCallback)
    {
        var self        = this,
            suggestions = self._suggestions
            ;

        if(!suggestions)
            return self.trigger('getSuggestions');

        if($.isFunction(renderCallback))
        {
            renderCallback(self);
        }
        else
        {
            self.renderSuggestions(self._suggestions);
        }

        self.showDropdown(self.containerElement());
    };

    TextExtAutocomplete.prototype.togglePreviousSuggestion = function()
    {
        var self     = this,
            selected = self.selectedSuggestionElement(),
            prev     = selected.prev()
            ;

        if(prev.length === 0) {
            self.hideDropdown();
            return;
        }

        self.clearSelected();
        prev.addClass("text-selected");
        self.scrollSuggestionIntoView(prev);
    };

    var TextExt = $.fn.textext.TextExt;

    TextExt.prototype.getFormData = function(keyCode) {
        var self = this,
            data = self.getWeightedEventResponse('getFormData', keyCode || 0);

        var input = data['input'];
        if ("," === input.charAt(input.length - 1)) {
            var tag = input.substr(0, input.length - 1);
            if(tag.length > 0) data['form'].push({name: tag});
            input = "";
        }

        self.trigger('setFormData'  , data['form']);
        self.trigger('setInputData' , input);
    };
})();
