class UserMailer < ActionMailer::Base
 
  def confirm_add_to_project(member, owner_user)
    @member = member
    @owner_user = owner_user
    mail(:to => member.user.email,
         :subject => "#{@owner_user.name} invited you to #{@member.project.name}"
    )
  end

  def add_to_project_new_user(member, owner_user)
    @member = member
    @owner_user = owner_user
    @url = member.user.has_changed_password? ? project_url(@member.project, :mid => @member.join_code) : new_user_password_url(:mid => @member.join_code)
    @label = member.user.has_changed_password ? "View Project" : "Create Password"
    mail(:to => member.user.email,
         :subject => "#{@owner_user.name} added you to project #{@member.project.name}"
    )
  end
  
  def add_to_project(member, owner_user)
    @member = member
    @owner_user = owner_user
    @url = member.user.has_changed_password? ? project_url(@member.project, :mid => @member.join_code) : new_user_password_url(:mid => @member.join_code)
    @label = member.user.has_changed_password ? "View Project" : "Create Password"
    mail(:to => member.user.email,
         :subject => "#{@owner_user.name} added you to project #{@member.project.name}"
    )
  end

  def remind_unjoined(member, owner_name, update_count, update_authors)
    @member_name = member.user.name
    @member_project = member.project.name
    @join_code = member.join_code
    @owner_name = owner_name
    @update_count = update_count
    @update_authors = update_authors
    mail(:to => member.user.email,
         :subject => "Friendly Reminder to Confirm Your Account"
    ) do |format|
      format.html { render :layout => "standard_email" }
    end
  end

  def notify_reactivated(member, owner_user)
    @member = member
    @owner_user = owner_user
    @url = member.user.has_changed_password? ? project_url(@member.project, :mid => @member.join_code) : new_user_password_url(:mid => @member.join_code)
    @label = member.user.has_changed_password ? "View Project" : "Create Password"
    mail(:to => member.user.email,
         :subject => "You have been reactivated on #{member.project.name}"
    )
  end

  def welcome(user)
    @name = user.name
    mail(:to => user.email,
         :subject => "Getting Started with LeanLaunchLab"
    )
  end

  def new_user_inactive(user)
    @name = user.name
    @project_list = user.live_projects.map(&:name).join(', ')
    mail(:to => user.email,
         :subject => "Do you need help with LeanLaunchLab?"
    ) do |format|
      format.html { render :layout => "standard_email" }
    end
  end

  def no_new_posts(member)
    @name = member.user.name
    @project_name = member.project.name
    mail(:to => member.user.email,
         :subject => "Reminder to update #{@project_name} in LeanLaunchLab"
    ) do |format|
      format.html { render :layout => "standard_email" }
    end
  end
  
end
