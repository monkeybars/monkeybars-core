require 'flickraw'

class FlickrBrowserModel
  attr_accessor :search_terms, :search_results
  
  def initialize
    @search_terms = ""
    @search_results = []
  end
  
  def search
    @search_results.clear
    unless @search_terms.empty?
      flickr.photos.search(:text => @search_terms).each do |photo|
        @search_results << photo
      end
    end
    @search_results
  end
  
  def find_sizes_by_id(id)
    flickr.photos.getSizes(:photo_id => id)
  end
end