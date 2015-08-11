class Api::ApiBaseController < ApplicationController

  skip_before_filter :verify_authenticity_token
  
  rescue_from CanCan::AccessDenied do |exception|
    logger.warn "WARNING: Invalid access attempt: #{exception.message}"
    head 403
  end
  
end