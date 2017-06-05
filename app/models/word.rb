class Word
  include Mongoid::Document
  
  field :text, type: String
  field :needsToBeReviewed, type: Integer

  embeds_many :pronunciations
  embeds_many :entries

  accepts_nested_attributes_for :pronunciations, :entries

  belongs_to :list

  def as_json(options = {})
    options[:except] ||= []
    options[:except] << :_id
    attrs = super(options)
    attrs[:id] = self._id.to_s
    attrs[:list_id] = self.list_id.to_s
    attrs[:pronunciations] = self.pronunciations.as_json
    attrs[:entries] = self.entries.as_json
    attrs
  end
end

