#encoding: utf-8
class UserMailer < ActionMailer::Base
 
  def confirm_add_to_project(member, owner_user)
    @member = member
    @owner_user = owner_user
    mail(:to => member.user.email,
         :subject => "#{@owner_user.name} te ha invitado a #{@member.project.name}"
    )
  end

  def add_to_project_new_user(member, owner_user)
    @member = member
    @owner_user = owner_user
    @url = member.user.has_changed_password? ? project_url(@member.project, :mid => @member.join_code) : new_user_password_url(:mid => @member.join_code)
    @label = member.user.has_changed_password ? "Ver proyecto" : "Definir Contraseña"
    mail(:to => member.user.email,
         :subject => "#{@owner_user.name} te ha agregado al proyecto #{@member.project.name}"
    )
  end
  
  def add_to_project(member, owner_user)
    @member = member
    @owner_user = owner_user
    @url = member.user.has_changed_password? ? project_url(@member.project, :mid => @member.join_code) : new_user_password_url(:mid => @member.join_code)
    @label = member.user.has_changed_password ? "Ver Proyecto" : "Definir Contraseña"
    mail(:to => member.user.email,
         :subject => "#{@owner_user.name} te ha agregado al proyecto #{@member.project.name}"
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
         :subject => "Te recordamos que confirmes tu cuenta"
    ) do |format|
      format.html { render :layout => "standard_email" }
    end
  end

  def notify_reactivated(member, owner_user)
    @member = member
    @owner_user = owner_user
    @url = member.user.has_changed_password? ? project_url(@member.project, :mid => @member.join_code) : new_user_password_url(:mid => @member.join_code)
    @label = member.user.has_changed_password ? "Ver Proyecto" : "Definir Contraseña"
    mail(:to => member.user.email,
         :subject => "Has sido reactivado en el proyecto #{member.project.name}"
    )
  end

  def welcome(user)
    @name = user.name
    mail(:to => user.email,
         :subject => "Comienza tu experiencia en Spartans Academy"
    )
  end

  def new_user_inactive(user)
    @name = user.name
    @project_list = user.live_projects.map(&:name).join(', ')
    mail(:to => user.email,
         :subject => "¿Necesitas ayuda para mejorar tu experiencia en Spartans Academy?"
    ) do |format|
      format.html { render :layout => "standard_email" }
    end
  end

  def no_new_posts(member)
    @name = member.user.name
    @project_name = member.project.name
    mail(:to => member.user.email,
         :subject => "Recordatorio de tu proyecto #{@project_name} en Spartans Academy"
    ) do |format|
      format.html { render :layout => "standard_email" }
    end
  end
  
end
