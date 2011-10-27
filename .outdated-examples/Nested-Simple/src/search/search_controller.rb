class SearchController < ApplicationController
  set_model 'SearchModel'
  set_view 'SearchView'
  set_close_action :close
  
  add_listener :type => :document, :components => {"search_text_field.document" => "search_text_field"}
  
  def when_search_changed(&block)
    @search_changed_callback = block
  end
  
  def search_text_field_insert_update(document_event)
    model.search_text = document_event.document.get_text(0, document_event.document.length)
    @search_changed_callback.call model.search_text unless @search_changed_callback.nil?
  end
  
  def search_text_field_remove_update(document_event)
    search_text_field_insert_update(document_event)
  end
end
