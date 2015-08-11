class ThirdParty::BrightideaController < ApplicationController
  
  skip_before_filter :require_login_and_password_change
  skip_before_filter :verify_authenticity_token
  skip_authorization_check
  
  def index
    if user_signed_in?
      params[:idea_list] ||= session[:brightidea_idea_list]
      if (organization_member = current_user.organization_members.where(:level => "Admin").last)
        Project.transaction do
          d = JSON.parse(params[:idea_list] || "[]")
          d.each do |idea|
            existing = Project.find_all_by_brightidea_id(idea["id"])
            if current_user.members.active.where(:project_id => existing.collect{|x| x.id}).count.zero?
              bi = ThirdParty::Brightidea.new(organization_member.organization.brightidea_api_key)
              bi_idea = bi.get_idea(idea["id"])              
              project = Project.new(
                :name => idea["title"],
                :pitch => idea["description"],
                :url => idea["url"],
                :organization_id => organization_member.organization_id,
                :brightidea_id => idea["id"]
              )
              if (success = project.save)
                bi_members = bi.get_member_list     
                bi_members.each do |bi_member|
                  unless (user = User.find_by_email(bi_member[:email].downcase))
                    unguessable_password = (0...20).map { 65.+(rand(25)).chr }.join
                    user = User.new(
                      :email => bi_member[:email],
                      :name => bi_member[:name],
                      :password => unguessable_password,
                      :password_confirmation => unguessable_password                   
                    )
                    user.has_changed_password = false
                    if (user.save)
                      organization_member.organization.organization_members.create!(:user => user)
                    else
                      raise
                    end
                  end                  
                  project.members.create!(
                    :user_id => user.id,
                    :is_owner => true, 
                    :level => "Owner", 
                    :role_name => "Manager"
                  )
                end
                unless project.members.where(:user_id => current_user.id).first
                  project.members.create!(
                    :user_id => current_user.id,
                    :is_owner => true, 
                    :level => "Owner", 
                    :role_name => "Manager"
                  )
                end
                UserActivity.create!(
                  :user => current_user,
                  :member => current_user.membership_on(project),
                  :name => current_user.name,
                  :email => current_user.email,
                  :action => "Create project",
                  :description => "#{current_user.name} created #{project}"
                )  
              end
            end
          end
        end
      else
        flash[:error] = "Sorry you must be an organization Admin to create projects"
        redirect_to(root_path)
        return
      end
      redirect_to last_projects_path
    else
      session[:brightidea_idea_list] = params[:idea_list]
      JSON.parse(params[:idea_list] || "[]").each do |idea|
        if (Project.find_by_brightidea_id(idea["id"]))
          redirect_to(new_user_session_path)
          return
        end
      end
      redirect_to(new_user_registration_path)
    end
  end

end