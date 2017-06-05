class Entry
  include Mongoid::Document

  field :lexicalCategory, type: String
  field :etymologies, type: Array

  embeds_many :senses
  accepts_nested_attributes_for :senses

  embedded_in :word

  def as_json(options = {})
    options[:except] ||= []
    options[:except] << :_id
    attrs = super(options)
    attrs[:id] = self._id.to_s
    # attrs[:word_id] = self.word_id.to_s
    attrs[:senses] = self.senses.as_json
    attrs
  end
end
