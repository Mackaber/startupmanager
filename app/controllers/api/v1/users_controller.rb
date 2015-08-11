class Api::V1::UsersController < Api::V1::V1BaseController
  
  load_and_authorize_resource
  
  def show
    render(:json => @user.to_hash)
  end
  
  def update
    if params.has_key?(:password)
      unless @user.valid_password?(params[:current_password])
        render(:status => 403, :json => ["invalid current password"])
        return
      end
    end
    
    success = false
    User.transaction do
      @user.name = params[:name].strip if params.has_key?(:name)
      @user.email = params[:email].strip if params.has_key?(:email)
      sa = {}
      if (params.has_key?(:time_zone))
        sa[:time_zone] = params[:time_zone]
      end
      if (params.has_key?(:home_page))
        sa[:home_page] = params[:home_page]
      end
      @user.setting_attributes = @user.setting.attributes.merge(sa) unless sa.empty?
      @user.password = params[:password] if params.has_key?(:password)
      @user.password_confirmation = params[:password_confirmation] if params.has_key?(:password_confirmation)
      
      password_changed = params.has_key?(:password)
      if (success = @user.save)
        sign_in(@user, :bypass => true) if password_changed
      end
    end
    if success
      @user.reload      # setting touches @user.updated_at which resets cache key
      respond_to do |format|
        format.json do
          render(:json => @user.to_hash)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @user.errors.full_messages)
        end
      end
    end
  end
    
end
