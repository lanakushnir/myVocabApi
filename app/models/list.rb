class List
  include Mongoid::Document
  # include Mongoid::Timestamps::Short

  field :date, type: Date
  has_many :words, dependent: :destroy, autosave: true

  def as_json(options = {})
    options[:except] ||= []
    options[:except] << :_id << :word_ids
    attrs = super(options)
    attrs[:id] = self._id.to_s
    attrs[:words] = self.words.map { |w| {id: w.id.to_s, text: w.text, needsToBeReviewed: w.needsToBeReviewed }}
    attrs
  end
end
