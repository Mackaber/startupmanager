class Snapshot < ActiveRecord::Migration
  def up
    create_table "attachments", :force => true do |t|
      t.string   "data_file_name",    :null => false
      t.string   "data_content_type", :null => false
      t.integer  "data_file_size",    :null => false
      t.datetime "data_updated_at",   :null => false
      t.integer  "item_id",           :null => false
      t.string   "item_type",         :null => false
      t.integer  "member_id",         :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "attachments", ["item_type", "item_id"], :name => "index_attachments_on_item_type_and_item_id"
    add_index "attachments", ["member_id"], :name => "index_attachments_on_member_id"

    create_table "audits", :force => true do |t|
      t.integer  "auditable_id",                   :null => false
      t.string   "auditable_type",                 :null => false
      t.integer  "associated_id"
      t.string   "associated_type"
      t.integer  "user_id"
      t.string   "user_type"
      t.string   "username"
      t.string   "action",                         :null => false
      t.text     "audited_changes",                :null => false
      t.integer  "version",         :default => 0, :null => false
      t.string   "comment"
      t.string   "remote_address"
      t.datetime "created_at"
    end

    add_index "audits", ["associated_id", "associated_type"], :name => "associated_index"
    add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
    add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
    add_index "audits", ["user_id", "user_type"], :name => "user_index"

    create_table "blog_posts", :force => true do |t|
      t.integer  "project_id",                       :null => false
      t.integer  "member_id",                        :null => false
      t.string   "subject",                          :null => false
      t.text     "body"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "the_ask"
      t.datetime "published_at"
      t.integer  "task_id"
      t.integer  "hypothesis_id"
      t.integer  "experiment_id"
      t.boolean  "urgent",        :default => false, :null => false
      t.date     "date"
      t.string   "post_type"
      t.string   "text1"
      t.string   "text2"
    end

    add_index "blog_posts", ["experiment_id"], :name => "index_blog_posts_on_experiment_id"
    add_index "blog_posts", ["hypothesis_id"], :name => "index_blog_posts_on_hypothesis_id"
    add_index "blog_posts", ["member_id"], :name => "index_blog_posts_on_member_id"
    add_index "blog_posts", ["project_id"], :name => "index_blog_posts_on_project_id"
    add_index "blog_posts", ["task_id"], :name => "index_blog_posts_on_goal_id"

    create_table "boxes", :force => true do |t|
      t.string "name",          :null => false
      t.string "label",         :null => false
      t.text   "description"
      t.string "startup_label", :null => false
    end

    add_index "boxes", ["name"], :name => "index_boxes_on_name", :unique => true

    create_table "canvas_items", :force => true do |t|
      t.integer  "project_id",                           :null => false
      t.integer  "box_id",                               :null => false
      t.string   "text",                                 :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "item_status_id", :default => 1
      t.integer  "original_id"
      t.boolean  "deleted",        :default => false,    :null => false
      t.string   "display_color",  :default => "yellow", :null => false
      t.integer  "hypothesis_id"
      t.text     "description"
      t.integer  "x"
      t.integer  "y"
      t.integer  "z"
      t.datetime "inactive_at"
      t.boolean  "added",          :default => false,    :null => false
      t.boolean  "updated",        :default => false,    :null => false
    end

    add_index "canvas_items", ["hypothesis_id"], :name => "index_canvas_items_on_hypothesis_id"
    add_index "canvas_items", ["original_id"], :name => "index_canvas_items_on_original_id"
    add_index "canvas_items", ["project_id"], :name => "index_canvas_items_on_project_id"

    create_table "charges", :force => true do |t|
      t.integer  "organization_id",                                 :null => false
      t.decimal  "amount",           :precision => 10, :scale => 2
      t.integer  "num_members"
      t.decimal  "member_price",     :precision => 10, :scale => 2
      t.text     "comments"
      t.date     "period_start",                                    :null => false
      t.date     "period_end",                                      :null => false
      t.string   "stripe_charge_id"
      t.datetime "created_at",                                      :null => false
      t.datetime "updated_at",                                      :null => false
    end

    add_index "charges", ["organization_id"], :name => "index_charges_on_organization_id"

    create_table "ckeditor_assets", :force => true do |t|
      t.string   "data_file_name",                  :null => false
      t.string   "data_content_type",               :null => false
      t.integer  "data_file_size",                  :null => false
      t.integer  "assetable_id"
      t.string   "assetable_type",    :limit => 30
      t.string   "type",              :limit => 30
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "ckeditor_assets", ["assetable_type", "assetable_id"], :name => "idx_ckeditor_assetable"
    add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], :name => "idx_ckeditor_assetable_type"

    create_table "comments", :force => true do |t|
      t.integer  "blog_post_id"
      t.integer  "member_id",     :null => false
      t.text     "body",          :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "hypothesis_id"
    end

    add_index "comments", ["blog_post_id"], :name => "index_comments_on_blog_post_id"
    add_index "comments", ["hypothesis_id"], :name => "index_comments_on_hypothesis_id"
    add_index "comments", ["member_id"], :name => "index_comments_on_member_id"

    create_table "experiments", :force => true do |t|
      t.integer  "project_id"
      t.integer  "hypothesis_id",    :null => false
      t.integer  "position"
      t.string   "title",            :null => false
      t.string   "success_criteria"
      t.date     "start_date"
      t.date     "end_date"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "item_status_id"
      t.datetime "completed_at"
    end

    add_index "experiments", ["hypothesis_id"], :name => "index_experiments_on_hypothesis_id"
    add_index "experiments", ["item_status_id"], :name => "index_experiments_on_item_status_id"
    add_index "experiments", ["project_id"], :name => "index_experiments_on_project_id"

    create_table "hypotheses", :force => true do |t|
      t.integer  "project_id"
      t.integer  "position"
      t.string   "title",          :null => false
      t.text     "description"
      t.integer  "item_status_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "completed_at"
      t.integer  "hypothesis_id"
    end

    add_index "hypotheses", ["hypothesis_id"], :name => "index_hypotheses_on_hypothesis_id"
    add_index "hypotheses", ["item_status_id"], :name => "index_hypotheses_on_item_status_id"
    add_index "hypotheses", ["project_id"], :name => "index_hypotheses_on_project_id"

    create_table "item_statuses", :force => true do |t|
      t.string   "status",     :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "item_statuses", ["status"], :name => "index_item_statuses_on_status", :unique => true

    create_table "member_blog_post_views", :force => true do |t|
      t.integer  "member_id",    :null => false
      t.integer  "blog_post_id", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "member_blog_post_views", ["blog_post_id", "member_id"], :name => "index_member_blog_post_views_on_blog_post_id_and_member_id"
    add_index "member_blog_post_views", ["member_id"], :name => "index_member_blog_post_views_on_member_id"

    create_table "members", :force => true do |t|
      t.integer  "user_id",                                        :null => false
      t.integer  "project_id",                                     :null => false
      t.string   "join_code"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "activated",                   :default => true
      t.string   "level",                                          :null => false
      t.boolean  "is_owner",                    :default => false
      t.string   "role_name",                                      :null => false
      t.boolean  "notify_hypotheses",           :default => true,  :null => false
      t.boolean  "notify_interviews",           :default => true,  :null => false
      t.boolean  "notify_updates",              :default => true,  :null => false
      t.boolean  "daily_summary",               :default => true,  :null => false
      t.boolean  "weekly_summary",              :default => true,  :null => false
      t.datetime "accessed_at"
      t.boolean  "display_plan_todo",           :default => true,  :null => false
      t.boolean  "display_plan_in_progress",    :default => true,  :null => false
      t.boolean  "display_plan_done",           :default => true,  :null => false
      t.boolean  "notify_hypotheses_validated", :default => true,  :null => false
    end

    add_index "members", ["join_code"], :name => "index_members_on_join_code", :unique => true
    add_index "members", ["project_id"], :name => "index_members_on_project_id"
    add_index "members", ["user_id", "project_id"], :name => "index_members_on_user_id_and_project_id", :unique => true

    create_table "organization_members", :force => true do |t|
      t.integer  "user_id",         :null => false
      t.integer  "organization_id", :null => false
      t.string   "level",           :null => false
      t.datetime "created_at",      :null => false
      t.datetime "updated_at",      :null => false
    end

    add_index "organization_members", ["organization_id"], :name => "index_organization_members_on_organization_id"
    add_index "organization_members", ["user_id", "organization_id"], :name => "index_organization_members_on_user_id_and_organization_id", :unique => true

    create_table "organizations", :force => true do |t|
      t.string   "name",                                                                      :null => false
      t.string   "organization_type"
      t.datetime "created_at",                                                                :null => false
      t.datetime "updated_at",                                                                :null => false
      t.decimal  "custom_yearly_price",     :precision => 10, :scale => 2
      t.decimal  "custom_monthly_price",    :precision => 10, :scale => 2
      t.string   "stripe_customer_id"
      t.integer  "cc_exp_month"
      t.integer  "cc_exp_year"
      t.string   "cc_last4"
      t.string   "cc_type"
      t.integer  "cc_user_id"
      t.string   "brightidea_api_key"
      t.date     "trial_end_date"
      t.date     "subscription_start_date"
      t.date     "subscription_end_date"
      t.integer  "subscription_level_id"
      t.boolean  "subscription_yearly",                                    :default => false, :null => false
      t.boolean  "invoice_billing",                                        :default => false, :null => false
    end

    add_index "organizations", ["brightidea_api_key"], :name => "index_organizations_on_brightidea_api_key"
    add_index "organizations", ["cc_user_id"], :name => "index_organizations_on_cc_user_id"
    add_index "organizations", ["name"], :name => "index_organizations_on_name"
    add_index "organizations", ["subscription_end_date"], :name => "index_organizations_on_subscription_end_date"
    add_index "organizations", ["subscription_level_id"], :name => "index_organizations_on_subscription_level_id"
    add_index "organizations", ["trial_end_date"], :name => "index_organizations_on_trial_end_date"

    create_table "projects", :force => true do |t|
      t.string   "name",                                           :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "pitch"
      t.string   "url"
      t.boolean  "canvas_startup_headers",      :default => false, :null => false
      t.boolean  "canvas_include_plan_default", :default => true,  :null => false
      t.boolean  "canvas_highlight_new",        :default => true,  :null => false
      t.integer  "organization_id",                                :null => false
      t.string   "brightidea_id"
    end

    add_index "projects", ["brightidea_id"], :name => "index_projects_on_brightidea_id"
    add_index "projects", ["organization_id", "name"], :name => "index_projects_on_organization_id_and_name", :unique => true

    create_table "questions", :force => true do |t|
      t.integer  "hypothesis_id", :null => false
      t.string   "title",         :null => false
      t.integer  "position"
      t.datetime "created_at",    :null => false
      t.datetime "updated_at",    :null => false
    end

    add_index "questions", ["hypothesis_id"], :name => "index_questions_on_hypothesis_id"

    create_table "settings", :force => true do |t|
      t.integer  "user_id",                                                  :null => false
      t.boolean  "post_email",     :default => true,                         :null => false
      t.boolean  "feedback_email", :default => true,                         :null => false
      t.boolean  "digest_email",   :default => false,                        :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "ui_version",     :default => 2,                            :null => false
      t.integer  "ui_available",   :default => 2
      t.string   "time_zone",      :default => "Pacific Time (US & Canada)", :null => false
    end

    create_table "signups", :force => true do |t|
      t.string   "email"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "signups", ["created_at"], :name => "index_signups_on_created_at"

    create_table "subscription_levels", :force => true do |t|
      t.string   "name",                                                                   :null => false
      t.string   "tagline"
      t.text     "description"
      t.boolean  "available",                                           :default => true,  :null => false
      t.decimal  "monthly_price",        :precision => 10, :scale => 2
      t.decimal  "yearly_price",         :precision => 10, :scale => 2
      t.integer  "trial_days",                                          :default => 30
      t.integer  "max_projects"
      t.integer  "max_members"
      t.integer  "max_storage_mb"
      t.decimal  "monthly_member_price", :precision => 10, :scale => 2
      t.integer  "free_members"
      t.boolean  "support_email",                                       :default => true,  :null => false
      t.boolean  "support_chat",                                        :default => false, :null => false
      t.boolean  "support_phone",                                       :default => false, :null => false
      t.datetime "created_at",                                                             :null => false
      t.datetime "updated_at",                                                             :null => false
    end

    create_table "tasks", :force => true do |t|
      t.integer  "project_id",            :null => false
      t.integer  "position"
      t.string   "title",                 :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "item_status_id"
      t.integer  "assigned_to_member_id"
      t.date     "due_date"
      t.integer  "hypothesis_id",         :null => false
      t.datetime "completed_at"
    end

    add_index "tasks", ["assigned_to_member_id"], :name => "index_tasks_on_assigned_to_member_id"
    add_index "tasks", ["hypothesis_id"], :name => "index_tasks_on_hypothesis_id"
    add_index "tasks", ["item_status_id"], :name => "index_goals_on_item_status_id"
    add_index "tasks", ["project_id"], :name => "index_goals_on_project_id"

    create_table "user_activities", :force => true do |t|
      t.integer  "user_id",     :null => false
      t.integer  "member_id"
      t.string   "name",        :null => false
      t.string   "email",       :null => false
      t.string   "action",      :null => false
      t.string   "description", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "user_activities", ["member_id"], :name => "index_user_activities_on_member_id"
    add_index "user_activities", ["user_id"], :name => "index_user_activities_on_user_id"

    create_table "users", :force => true do |t|
      t.string   "email",                                                    :null => false
      t.string   "encrypted_password",     :limit => 128,                    :null => false
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",                         :default => 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.string   "confirmation_token"
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name",                                                     :null => false
      t.boolean  "has_changed_password",                  :default => true,  :null => false
      t.boolean  "admin",                                 :default => false, :null => false
    end

    add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
    add_index "users", ["email"], :name => "index_users_on_email", :unique => true
    add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

    add_foreign_key "attachments", "members", :name => "attachments_member_id_fk"

    add_foreign_key "blog_posts", "experiments", :name => "blog_posts_experiment_id_fk", :dependent => :nullify
    add_foreign_key "blog_posts", "hypotheses", :name => "blog_posts_hypothesis_id_fk", :dependent => :nullify
    add_foreign_key "blog_posts", "members", :name => "blog_posts_member_id_fk", :dependent => :delete
    add_foreign_key "blog_posts", "projects", :name => "blog_posts_project_id_fk", :dependent => :delete
    add_foreign_key "blog_posts", "tasks", :name => "blog_posts_task_id_fk", :dependent => :nullify

    add_foreign_key "canvas_items", "boxes", :name => "canvas_items_box_id_fk"
    add_foreign_key "canvas_items", "canvas_items", :name => "canvas_items_original_id_fk", :column => "original_id"
    add_foreign_key "canvas_items", "hypotheses", :name => "canvas_items_hypothesis_id_fk", :dependent => :nullify
    add_foreign_key "canvas_items", "item_statuses", :name => "canvas_items_item_status_id_fk", :dependent => :nullify
    add_foreign_key "canvas_items", "projects", :name => "canvas_items_project_id_fk", :dependent => :delete

    add_foreign_key "charges", "organizations", :name => "charges_organization_id_fk"

    add_foreign_key "comments", "blog_posts", :name => "comments_blog_post_id_fk", :dependent => :delete
    add_foreign_key "comments", "hypotheses", :name => "comments_hypothesis_id_fk", :dependent => :delete
    add_foreign_key "comments", "members", :name => "comments_member_id_fk", :dependent => :delete

    add_foreign_key "experiments", "hypotheses", :name => "experiments_hypothesis_id_fk", :dependent => :nullify
    add_foreign_key "experiments", "item_statuses", :name => "experiments_item_status_id_fk", :dependent => :nullify
    add_foreign_key "experiments", "projects", :name => "experiments_project_id_fk", :dependent => :delete

    add_foreign_key "hypotheses", "hypotheses", :name => "hypotheses_hypothesis_id_fk", :dependent => :nullify
    add_foreign_key "hypotheses", "item_statuses", :name => "hypotheses_item_status_id_fk", :dependent => :nullify
    add_foreign_key "hypotheses", "projects", :name => "hypotheses_project_id_fk", :dependent => :delete

    add_foreign_key "member_blog_post_views", "blog_posts", :name => "member_blog_post_views_blog_post_id_fk", :dependent => :delete
    add_foreign_key "member_blog_post_views", "members", :name => "member_blog_post_views_member_id_fk", :dependent => :delete

    add_foreign_key "members", "projects", :name => "members_project_id_fk", :dependent => :delete
    add_foreign_key "members", "users", :name => "members_user_id_fk"

    add_foreign_key "organization_members", "organizations", :name => "organization_members_organization_id_fk", :dependent => :delete
    add_foreign_key "organization_members", "users", :name => "organization_members_user_id_fk", :dependent => :delete

    add_foreign_key "organizations", "subscription_levels", :name => "organizations_subscription_level_id_fk"
    add_foreign_key "organizations", "users", :name => "organizations_cc_user_id_fk", :column => "cc_user_id"

    add_foreign_key "projects", "organizations", :name => "projects_organization_id_fk"

    add_foreign_key "questions", "hypotheses", :name => "questions_hypothesis_id_fk"

    add_foreign_key "settings", "users", :name => "settings_user_id_fk", :dependent => :delete

    add_foreign_key "tasks", "hypotheses", :name => "tasks_hypothesis_id_fk", :dependent => :nullify
    add_foreign_key "tasks", "item_statuses", :name => "goals_item_status_id_fk", :dependent => :nullify
    add_foreign_key "tasks", "members", :name => "tasks_assigned_to_member_id_fk", :column => "assigned_to_member_id", :dependent => :nullify
    add_foreign_key "tasks", "projects", :name => "goals_project_id_fk", :dependent => :delete

    add_foreign_key "user_activities", "members", :name => "user_activities_member_id_fk", :dependent => :nullify
    add_foreign_key "user_activities", "users", :name => "user_activities_user_id_fk", :dependent => :delete
  end

  def down
  end
end
