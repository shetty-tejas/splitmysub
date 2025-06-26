module MetaTags
  extend ActiveSupport::Concern

  included do
    before_action :setup_meta_tags
  end

  private

  def setup_meta_tags
    @meta_tags = {}
  end

  def set_meta_tag(key, value)
    @meta_tags[key] = value
  end

  def meta_tag(key)
    @meta_tags[key]
  end

  # Helper method to maintain compatibility with existing content_for calls
  def content_for(key, value = nil)
    if value
      set_meta_tag(key, value)
    else
      meta_tag(key)
    end
  end
end
