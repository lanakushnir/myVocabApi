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

    if params[:word][:text].present? && params[:word][:lexicalCategory].present? && params[:word][:senses].present? && params[:word][:senses] !=0 
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
    update_params = word_params
    update_params["senses"].each do |s|
      s.delete("id") if s["id"].nil?
    end
    update_params["pronunciations"].each do |p|
      p.delete("id") if p["id"].nil?
    end

    if @word.update(update_params)
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

    api_json["results"].each do |result_json|
      word_json["text"] = result_json["word"]
      lexical_entry_json = result_json["lexicalEntries"][0]
      word_json["needsToBeReviewed"] = 10
      word_json["lexicalCategory"] = lexical_entry_json["lexicalCategory"].downcase
      word_json["pronunciations"] = lexical_entry_json["pronunciations"].try(:map) { |p| { "audioFile" => p["audioFile"], "phoneticSpelling" => p["phoneticSpelling"] }}

      entry_json = lexical_entry_json["entries"][0]
      
      senses = entry_json["senses"].map do |s|
        sense = {}
        if s["definitions"].blank?
          next
        else
          sense["definition"] = s["definitions"][0] 
        end
        sense["example"] = s["examples"][0]["text"] unless s["examples"].blank?
        sense
      end
      word_json["senses"] = senses.select { |s| !s.nil? }
      word_json["etymologies"] = entry_json["etymologies"]
      word_json["list_id"] = getTodayListId
    end
    return word_json
  end

  def parseParams(params_json)
    senses = params_json[:senses].select { |s| s[:definition] }
    return nil unless senses.any?

    word_json = {}
    word_json[:text] = params_json[:text]
    word_json[:lexicalCategory] = params_json[:lexicalCategory]
    word_json[:needsToBeReviewed] = 10
    word_json[:senses] = senses.try(:map) { |s| { 'definition' => s[:definition], 'example' => s[:example] }}
    word_json[:pronunciations] = params_json[:pronunciations].try(:map) { |p| { 'audioFile' => p[:audioFile], 'phoneticSpelling' => p[:phoneticSpelling] }}
    word_json[:etymologies] = params_json[:etymologies]
    word_json[:list_id] = getTodayListId
    word_json
  end

  def getTodayListId()
    list = List.find_or_create_by(date: Date.today)
    return list.id
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_word
      @word = Word.where(text: params[:text]).first
    end

    # Only allow a trusted parameter "white list" through.
    def word_params
      params.require(:word).permit(:id, :list_id, :text, :lexicalCategory, :needsToBeReviewed, etymologies: [],
                                    pronunciations: [ :id, :phoneticSpelling, :audioFile], 
                                    senses: [ :id, :definition, :example ])
    end
end
