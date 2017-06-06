class WordsController < ApplicationController
  before_action :set_word, only: [:show, :update, :destroy]

  # GET /words
  def index
    @words = Word.all

    render json: @words
  end

  # GET /words/1
  def show
    render json: @word
  end

  # POST /words
  def create
    existing_word = Word.where(text: params[:word][:text]).first
    if existing_word
      existing_word.list_id = getTodayListId
      if existing_word.save
        json = existing_word.as_json
        json["does_exist"] = true 
        render json: json and return
      end
    end

    if params[:word][:text].present? && params[:word][:pronunciations].present?
      word_json = parseParams(word_params)
    else
      word_json = callApi( params[:word][:text] ) 
    end
    
    @word = Word.new(word_json)
    if @word.save
      render json: @word, status: :created, location: @word
    else
      render json: @word.errors, status: :unprocessable_entity  
    end

  end

  # PATCH/PUT /words/1
  def update
    if @word.update(word_params)
        render json: @word and return
    end
    render json: @word.errors, status: :unprocessable_entity and return
  end

  # DELETE /words/1
  def destroy
    list_id = @word.list_id
    @word.destroy
    if arr = Word.where(list_id: list_id).count == 0
      List.find(id: list_id).destroy()
    end
  end

  def callApi(name)
    require "net/http"

    id = "a18b7efa"
    key = "40d9d7654e48c22b03a0b697307da954"
    url = "https://od-api.oxforddictionaries.com/api/v1/entries/en/"

    header = { "accept" => "application/json", "app_id" => id, "app_key" => key }
    uri = URI(url + name.downcase)
    request = Net::HTTP::Get.new(uri)
    request.initialize_http_header(header)
    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == "https") { |http| http.request request }

    if (response.code != '404') 
      json = JSON.parse(response.body)
      word_json = parseApi(json)
    else
      response
    end
  end

  def parseApi(api_json)
    word_json = {}
    api_json['results'].each do |result_json|
      word_json['text'] = result_json['word']
      word_json['needsToBeReviewed'] = 10
      word_json['pronunciations'] = result_json['lexicalEntries'][0]['pronunciations'].try(:map) { |p| { 'audioFile' => p['audioFile'], 'phoneticSpelling' => p['phoneticSpelling'] }}
      entries = result_json['lexicalEntries'].map do |lexical_entry_json|
        word_entry_json = {}
        word_entry_json['lexicalCategory'] = lexical_entry_json['lexicalCategory'].downcase
        lexical_entry_json['entries'].each do |entry_json|
          word_entry_json['etymologies'] = entry_json['etymologies']
          senses = entry_json['senses'].map do |s|
            sense = {}
            if s['definitions'].blank?
              next
            else
              sense['definition'] = s['definitions'][0]
            end
            sense['example'] = s['examples'][0]["text"] unless s['examples'].blank?
            sense
          end
          word_entry_json['senses'] = senses.select { |s| !s.nil? }
        end
        word_entry_json
      end
      word_json['entries'] = entries.select { |e| !e.nil? }
      word_json['list_id'] = getTodayListId
    end
    return word_json
  end

  def parseParams(params)
    params_json = params.to_h
    pronunciations = params_json['pronunciations'].select { |p| p['phoneticSpelling'] }
    entries = params_json['entries'].select do |entry| 
      senses = entry['senses']
      senses.select! { |s| s['definition'] }
      entry['lexicalCategory'] && senses.count > 0
    end
    return nil unless pronunciations && entries

    word_json = {}
    word_json['text'] = params_json['text']
    word_json['needsToBeReviewed'] = 10
    word_json['pronunciations'] = pronunciations
    word_json['entries'] = entries
    word_json['list_id'] = getTodayListId
    word_json
  end

  def getTodayListId()
    list = List.find_or_create_by(date: Date.today)
    return list.id
  end

  private
    # actionpack/lib/action_controller/metal/strong_parameters.rb
    def to_h
      if permitted?
        @parameters.to_h
      else
        slice(*self.class.always_permitted_parameters).permit!.to_h
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_word
      @word = Word.where(text: params[:text]).first
    end

    # Only allow a trusted parameter "white list" through.
    def word_params
      parameters = params.require(:word).permit(:id, :list_id, :text, :needsToBeReviewed,
                                    pronunciations: [ :id, :phoneticSpelling, :audioFile], 
                                    entries: [ :id, :lexicalCategory, etymologies: [], senses: [ :id, :definition, :example ]])
      parameters["entries"].each do |e|
        e.delete("id") if e["id"].nil?
        e["senses"].each do |s|
          s.delete("id") if s["id"].nil?
        end
      end
      parameters["pronunciations"].each do |p|
        p.delete("id") if p["id"].nil?
      end
      parameters
    end
end

