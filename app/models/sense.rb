class Sense
  include Mongoid::Document

  field :definition, type: String
  field :example, type: String

  embedded_in :entry

  def as_json(options = {})
    options[:except] ||= []
    options[:except] << :_id
    attrs = super(options)
    attrs[:id] = self._id.to_s
    attrs
  end
end