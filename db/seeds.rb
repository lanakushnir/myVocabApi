# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

List.collection.drop()

lists_json = JSON.parse(File.read("#{Rails.root}/db/word-lists.json"))

lists_json.each do |list_json|
	
	list = List.new({ date: list_json["date"] })

	list_json["words"].each do |word_json|
		w = Word.new({ text: word_json["text"], lexicalCategory: word_json["lexicalCategory"], etymologies: word_json["etymologies"], needsToBeReviewed: word_json["needsToBeReviewed"] })
		word_json["pronunciations"].each do |pronunciation_json|
			w.pronunciations.build({ phoneticSpelling: pronunciation_json["phoneticSpelling"], audioFile: pronunciation_json["audioFile"] })
		end
		word_json["senses"].each do |sense_json|
			w.senses.build({ definition: sense_json["definition"], example: sense_json["example"] })
		end
		w.save
		list.words << w
	end
	list.save
	
	  puts "#{list.date} list has #{list.words.count} words"
end







# collections_json.each do |collection_json|
#   collection = QuestionCollection.new({title: collection_json['title'], price_tier: collection_json['price_tier'], image: File.open(Rails.root + collection_json['image_url']),
#                                        app_store_product_id: collection_json['app_store_product_id'], apple_id: collection_json['apple_id'],
#                                        sort_order: collection_json['sort_order'], is_ready_for_sale: collection_json['is_ready_for_sale']})
#   collection_json['questions'].each do |question_json|
#     q = QuestionPrototype.new({text: question_json['text'], zoom_x: question_json['zoom_x'], zoom_y: question_json['zoom_y'],
#                                ambience: question_json['ambience'],
#                                theme: question_json['theme'], image: File.open(Rails.root + question_json['image_url'])})
#     question_json['answers'].each do |answer_json|
#       q.answers.build(text: answer_json['text'], is_correct: answer_json['is_correct'])
#     end
#     q.save
#     collection.question_prototypes << q
#   end
#   collection.save

#   puts "#{collection.title} has #{collection.question_prototypes.count} questions"
# end
















