class ActiveAdminSessionsController::SessionsController < Devise::SessionsController
  skip_authorization_check
end
