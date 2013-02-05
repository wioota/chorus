chorus.Mixins.TagsContext = {
  additionalContextForTags: function() {
      return {
          tags: this.model.tags().models,
          tagWorkspaceId: this.options.tagWorkspaceId
      };
  }
};