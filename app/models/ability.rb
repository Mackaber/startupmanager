class Ability
  include CanCan::Ability

  attr_accessor :user
  
  def initialize(user)
    @user = (user || User.new)   # guest user (not logged in)
    
    # if (@user.admin)
    #   can :manage, :all
    #   
    # else
      can do |action, subject_class, subject|
        r = case subject_class.name
        when "Attachment"
          member = @user.members.active.where(:project_id => subject.item.project_id).first if (subject)
          case action
          when :index
            member
          else
            member && (member.level != "Viewer") && !(member.project.organization.auto_locked || member.project.organization.admin_locked)
          end
          
        when /^(BlogPost|CanvasItem|Hypothesis|Experiment|ProjectTask|Question)$/
          member = @user.members.active.where(:project_id => subject.project_id || (subject.respond_to?(:hypothesis_id) && subject.hypothesis_id && subject.hypothesis.project_id)).first if (subject)
          member && (member.level != "Viewer") && !(member.project.organization.auto_locked || member.project.organization.admin_locked)
            
        when "Charge"
          @user.admin
          
        when "Comment"
          member = @user.members.active.where(:project_id => subject.subject.project_id).first if (subject)
          case action
          when :create
            member && (member.level != "Viewer") && !(member.project.organization.auto_locked || member.project.organization.admin_locked)
          when :destroy                 # creator or owner can destroy comments
            member && (member.level == "Owner" || member == subject.member) &&  !(member.project.organization.auto_locked || member.project.organization.admin_locked)
          else                          # creator can update comments
            member && (member == subject.member) && !(member.project.organization.auto_locked || member.project.organization.admin_locked)
          end
        
          # for nested index actions the subject will be a hash from parent_instance => child_class
          when "Hash"
            if (subject)
              subject = subject.to_a[0]
              parent, child_class = subject[0], subject[1]
              case parent.class.name
              when "BlogPost"
                member = @user.members.active.where(:project_id => parent.project_id).first
                case child_class.name
                when "Attachment"
                  case action
                  when :index
                    member
                  else
                    raise "unrecognized BlogPost / Attachment check: #{action}"
                  end
                else
                  raise "unrecognized BlogPost resource check: #{child_class.name}"
                end

              when "Experiment"
                member = @user.members.active.where(:project_id => parent.project_id).first
                case child_class.name
                when "Attachment"
                  case action
                  when :index
                    member
                  else
                    raise "unrecognized Experiment / Attachment check: #{action}"
                  end
                else
                  raise "unrecognized Experiment resource check: #{child_class.name}"
                end

              when "Hypothesis"
                member = @user.members.active.where(:project_id => parent.project_id).first
                case child_class.name
                when "Attachment"
                  case action
                  when :index
                    member
                  else
                    raise "unrecognized Hypothesis / Attachment check: #{action}"
                  end
                else
                  raise "unrecognized Hypothesis resource check: #{child_class.name}"
                end

              when "Organization"
                member = @user.organization_members.where(:organization_id => parent.id).first
                case child_class.name
                when "OrganizationMember"
                  case action
                  when :import
                    member && (member.level == "Admin")
                  when :index
                    member
                  else
                    raise "unrecognized organization / member check: #{action}"
                  end
                else
                  raise "unrecognized Organization resource check: #{child_class.name}"
                end

              when "Project"
                member = @user.members.active.where(:project_id => parent.id).first
                case child_class.name
                when /^(BlogPost|Hypothesis|ProjectTask)$/
                  case action
                  when :index
                    member
                  end                
                when "Member"
                  case action
                  when :import
                    member && (member.level == "Owner")
                  when :index
                    member
                  else
                    raise "unrecognized project / member check: #{action}"
                  end
                else
                  raise "unrecognized Project resource check: #{child_class.name}"
                end

              when "ProjectTask"
                member = @user.members.active.where(:project_id => parent.project_id).first
                case child_class.name
                when "Attachment"
                  case action
                  when :index
                    member
                  else
                    raise "unrecognized ProjectTask / Attachment check: #{action}"
                  end
                else
                  raise "unrecognized ProjectTask resource check: #{child_class.name}"
                end

              when "User"
                case child_class.name
                when "Setting"
                  @user == parent
                else
                  raise "unrecognized User resource check: #{child_class.name}"
                end

              else
                raise "unrecognized permission Hash #{parent.class.name} #{child_class.name}"
              end
            else
              raise "unspecified permission Hash"
            end

        when "Help"
          case action
          when :index, :show
            true
          else
            @user.admin
          end
          
        when "Member"
          member = @user.members.active.where(:project_id => subject.project_id).first if (subject)
          case action
          when :index
            member
          when :destroy, :remove
            (@user.new_record? && subject.join_code) || (member == subject) || (member && (member.level == "Owner"))
          when :update
            (member == subject) || (member && (member.level == "Owner"))
          else
            member && (member.level == "Owner")
          end
        
        when "Organization"
          member = @user.organization_members.where(:organization_id => subject.id).first if (subject)    
          case action
          when :index                   # everyone can list their orgs
            true
          when :show
            member || subject.nil?
          else
            member && (member.level == "Admin")
          end
          
        when "OrganizationMember"
          member = @user.organization_members.where(:organization_id => subject.organization_id).first if (subject)          
          case action
          when :index                   # the parent organization will be checked first
            true
          when :update, :show
            member && (member == subject || member.level == "Admin")
          else
            member && (member.level == "Admin")
          end
          
        when "Project"
          member = @user.members.active.where(:project_id => subject.id).first if (subject)
          case action
          when :create
            if (subject.organization_id.nil?)
              true
            else
              org_member = @user.organization_members.where(:organization_id => subject.organization_id).first
              org_member && org_member.level == "Admin"
            end
          when :index, :last, :last_canvas, :start   # anyone can create a project and list their projects
            true
          when :canvas, :show, :interviews, :journal           # any member can show a project
            member || subject.nil?            
          else                          # owners can destroy/update a project
            (member && (member.level == "Owner")) || (subject && (om = @user.organization_members.where(:organization_id => subject.organization_id).first) && om.level == "Admin")
          end
          
        when "Setting"
          @user == subject.user
          
        when "User"
          @user == subject
          
        else
          raise "no ability rules defined for #{subject_class}/#{action}"
        end
        
        r = !!r
        
        Rails.logger.debug "can? #{action} #{subject_class} #{subject.inspect} => #{r}"
        
        r
      end       # can      
    # end       # user.admin
  end
end
