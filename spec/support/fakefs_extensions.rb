module FakeFS
  class FakeDir
    def delete(node = self)
      if node == self
        parent.entry.delete(self)
      else
        @entries.delete(node.name)
      end
    end
  end
end
