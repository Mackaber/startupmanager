require "csv"

class Api::V1::MembersController < Api::V1::V1BaseController
  
  load_and_authorize_resource :project
  load_and_authorize_resource :through => :project, :shallow => true
  
  skip_before_filter :require_login_and_password_change, :only => [:destroy]
  skip_authorization_check :only => [:destroy]
      
  def create
    attrs = load_params
    member = nil
    Member.transaction do
      @project.lock!
      member = process_member(params[:user][:name], params[:user][:email], attrs[:level], attrs[:role_name])
    end
    if member && member.errors.empty?
      UserActivity.create(:user => current_user,
                          :member => current_user.membership_on(@project),
                          :name => current_user.name,
                          :email => current_user.email,
                          :action => "Invited",
                          :description => "#{current_user.name} invited #{member.user.name} to project #{@project.name}")
      
      respond_to do |format|
        format.json do
          # send down updated list of org members
          members = [member]
          organization_members = member.project.organization.organization_members
          users = [members.collect{|x| x.user} + organization_members.collect{|x| x.user}].flatten.uniq
          render(:json => {
            :members => members.collect{|x| x.to_hash},
            :organization_members => organization_members.collect{|x| x.to_hash},
            :organizations => [member.project.organization.to_hash],
            :users => users.collect{|x| x.to_hash}
          })
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => member.errors)
        end
      end
    end
  end
  
  def destroy
    if user_signed_in?
      authorize! :destroy, @member
    else
      if @member.join_code.nil?
        render(:status => 403, :json => "access denied")
        return
      end
    end
    success = nil
    Member.transaction do
      @member.project.lock!
      if (success = @member.deactivate)
        if (!user_signed_in? || current_user.id == @member.user_id)
          Resque.enqueue(Jobs::Notify::MemberDeactivated, @member.id, user_signed_in? ? current_user.id : nil)     
        end
      end
    end
    if success
      respond_to do |format|
        format.json do
          h = @member.to_hash
          h[:organizations] = [@member.project.organization.to_hash]
          render(:json => h)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @member.errors)
        end
      end
    end
  end
  
  def import
    members = []
    errors = []
    Member.transaction do
      @project.lock!
      CSV.new(params[:data], :col_sep => "\t").each_with_index do |row,i|
        name = row[0]
        email = row[1]
        level = row[2]
        role = row[3]
        # blank row
        if (name.blank? && email.blank? && level.blank? && role.blank?)
          next
        end
        # header row
        if (i == 0 && !Devise.email_regexp.match(email))
          next
        end
        if (name.blank? || !Devise.email_regexp.match(email))
          errors << row
        else
          if level.blank?
            level = "Normal" 
          else
            level = level.strip.titlecase
          end
          if role.blank?
            role = "Contributor" 
          else
            role = role.strip.titlecase
          end
          member = process_member(name, email, level, role)
          if (member && member.errors.empty?)
            members << member
          else
            errors << row
          end
        end
      end    
    end
    render(:json => {
      :members => members.collect{|x| h = x.to_hash; h[:user] = x.user.to_hash; h},
      :errors => errors
    })
  end
  
  def index
    members = current_user.members.active
    render(:json => members.collect{|x| x.to_hash})
  end
  
  def update
    @member.attributes = load_params
    authorize! :assign_roles, @member if (@member.level_changed? || @member.role_name_changed?)
    success = false
    Member.transaction do
      @member.project.lock!
      success = @member.save
    end
    if success
      respond_to do |format|
        format.json do
          render(:json => @member.to_hash)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @member.errors)
        end
      end
    end    
  end
  
  def load_params
    attrs = {}
    [:level, [:role_name, :role], :display_plan_done, :display_plan_in_progress, :display_plan_todo, :plan_done_sort, :notify_goals, :notify_hypotheses, :notify_hypotheses_validated, :notify_interviews, :notify_updates, :daily_summary, :weekly_summary].each do |a|
      if (a.is_a?(Array))
        key, value = a[0], a[1]
      else
        key, value = a, a
      end
      attrs[key] = params[value] if params.has_key?(value)
    end
    return attrs
  end
  protected :load_params  
    
  def process_member(name, email, level, role)
    unless (user = User.find_by_email(email.downcase))
      new_user = true
      unguessable_password = (0...20).map { 65.+(rand(25)).chr }.join
      user = User.new(
        :email => email,
        :name => name,
        :password => unguessable_password,
        :password_confirmation => unguessable_password
      )
      user.has_changed_password = false
      if (user.save)      
        @project.organization.organization_members.create!(:user => user)
      else
        render(:status => 400, :json => user.errors)
        return nil
      end
    end
    if (member = user.members.where(:project_id => @project.id).first)
    else
      new_member = true
      member = Member.new
      member.user = user
      member.project = @project
    end
    member.level = level
    member.role_name = role
    member.activated = true    
    if (member.save)
      Resque.enqueue(Jobs::Notify::MemberActivated, current_user.id, member.id, new_user, new_member)
    end
    return member
  end
  protected :process_member
    
end
