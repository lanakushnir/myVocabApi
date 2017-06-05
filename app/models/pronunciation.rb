class Pronunciation
  include Mongoid::Document

  field :audioFile, type: String
  field :phoneticSpelling, type: String

  embedded_in :word

  def as_json(options = {})
    options[:except] ||= []
    options[:except] << :_id
    attrs = super(options)
    attrs[:id] = self._id.to_s
    attrs
  end
end