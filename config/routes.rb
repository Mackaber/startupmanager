LeanLaunchLab::Application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  resources :errors, :only => [:create]

  post "/email" => "email#index"

  match "/activity_stream", :to => redirect("/admin/user_activities")
  
  resources :resources, :only => [:show]
  
  devise_scope :user do
    match "/users/password/check-email" => "custom_devise/passwords", :action => "check_email", :as => "check_email_password"
  end
  devise_for :users, :controllers => {:confirmations => "custom_devise/confirmations", :passwords => "custom_devise/passwords", :registrations => "custom_devise/registrations", :sessions => "custom_devise/sessions"}

  resources :settings, :only => :update

  resources :signups, :only => [:create]
  
  resource :user
  get "/user/edit" => "users#edit", :as => "edit_current_user"
  put "/user/update" => "users#update", :as => "update_current_user"
  get "/user/need_email_confirmation" => "users#need_email_confirmation", :as => "need_email_confirmation"
  get "/user/settings" => "users#edit_settings", :as => "edit_settings"
  post "/user/update_setting" => "users#update_setting", :as => "update_setting"

  resource :help, :only => [:show]
  
  resources :organizations, :only => [:show] do
    collection do
      get "last"
    end
    
    member do
      get "payment"
    end
  end
  
  resources :organization_members, :only => [:index]
  
  resources :projects, :only => [:edit, :index, :show] do
    collection do
      get "last"
      get "last_canvas"
      get "start"
    end
    
    member do
      get "canvas"
      get "interviews"
      get "journal"
    end
    
    resources :tasks, :only => [:index]
    
    resources :attachments, :only => [:show]
    
    resources :members, :only => [:destroy, :index] do
      member do
        get "remove"
      end
    end
  end
  
  match "payments/:id", :to => "payments#edit", :via => :get
  match "payments/:id", :to => "payments#update", :via => :post
  match "org-payments/:id", :to => "organization_member_payments#edit", :via => :get
  match "org-payments/:id", :to => "organization_member_payments#update", :via => :post
  
  resource :settings, :only => [] do
    member do 
      get "profile"
      get "notifications"
    end
  end
  
  scope :module => "api" do  
    
    namespace :v1, :defaults => {:format => :json} do      
      resources :attachments, :only => [:create, :destroy, :index]
      resources :blog_posts, :only => [:create, :destroy, :index, :update]
      resources :canvas_items, :only => [:create, :destroy, :update]
      resources :comments, :only => [:create, :destroy, :update]
      resources :contacts, :only => [:create]
      resources :experiments, :only => [:create, :destroy, :update]
      resources :hypotheses, :only => [:create, :destroy, :index, :update]
      resources :members, :only => [:create, :destroy, :index, :update] do
        collection do
          post "import"
        end
      end
      resources :organizations, :only => [:index, :show, :update]
      resources :organization_members, :only => [:create, :destroy, :update] do
        collection do
          post "import"
        end
      end
      resources :projects, :only => [:create, :destroy, :index, :show, :update]
      resources :questions, :only => [:create, :destroy, :update]
      resources :resource_questions, :only => [:create]
      resources :tasks, :only => [:create, :destroy, :update]
      resources :updates, :only => [:index]
      resources :users, :only => [:show, :update]     
    end
    
  end
  
  namespace :admin do
    
    resources :charges, :only => [:destroy, :index]

    resources :organizations, :only => [:destroy, :edit, :index, :update]
    
    resources :projects, :only => [:index] do
      member do
        get "export"
      end
    end
    
    resources :signups, :only => [:index]
    
    resources :users, :only => [:destroy, :edit, :index]
    
    resources :user_activities, :only => [:index]
    
    resources :absurdities, :only => [:index, :show, :create]
    
    root :to => "admin#index"
  end

  #copied from the ckeditor gem /config/routes.rb
  #if this isn't here the wildcard route below takes precedence
  namespace :ckeditor, :only => [:index, :create, :destroy] do
    resources :pictures
    resources :attachment_files
  end
  
  match "robots", :controller => "robots", :action => "index"
  
  match "brightidea", :controller => "third_party/brightidea", :action => "index"

  root :to => "landing#index"

  #match static pages; terms of service, privacy policy...
  match 'privacy', :controller => "static", :as => 'privacy'
  match 'terms', :controller => "static", :as => 'terms'
  
  match "*path", :to => "default#index"
end
