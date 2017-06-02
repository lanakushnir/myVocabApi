class Pronunciation
  include Mongoid::Document

  field :phoneticSpelling, type: String
  field :audioFile, type: String

  embedded_in :word

  def as_json(options = {})
    options[:except] ||= []
    options[:except] << :_id
    attrs = super(options)
    attrs[:id] = self._id.to_s
    attrs
  end
end