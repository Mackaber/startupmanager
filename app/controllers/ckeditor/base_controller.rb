class Ckeditor::BaseController < ApplicationController
  
  skip_authorization_check
  
  skip_before_filter :verify_authenticity_token, :only => [:create]
  # the above monkey patch is temporary.
  # See https://github.com/galetahub/ckeditor/issues/15 for further discussion

  respond_to :html, :json
  layout "ckeditor"

  before_filter :set_locale
  before_filter :find_asset, :only => [:destroy]
  before_filter :ckeditor_authenticate

  protected

  def set_locale
    if !params[:langCode].blank? && I18n.available_locales.include?(params[:langCode].to_sym)
      I18n.locale = params[:langCode]
    end
  end

  def respond_with_asset(asset)
    file = params[:CKEditor].blank? ? params[:qqfile] : params[:upload]
    asset.data = Ckeditor::Http.normalize_param(file, request)

    callback = ckeditor_before_create_asset(asset)

    if callback && asset.save
      # TODO fix whatever consumes this JSON not to expect "asset." in the result
      ActiveRecord::Base.include_root_in_json = true
      body = params[:CKEditor].blank? ? asset.to_json(:only=>[:id, :type]) : %Q"<script type='text/javascript'>
          window.parent.CKEDITOR.tools.callFunction(#{params[:CKEditorFuncNum]}, '#{Ckeditor::Utils.escape_single_quotes(asset.url_content)}');
        </script>"
      ActiveRecord::Base.include_root_in_json = false
      render :text => body
    else
      render :nothing => true
    end
  end
end
