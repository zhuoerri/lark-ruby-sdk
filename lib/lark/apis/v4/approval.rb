module Lark
  module Apis
    module V4
      module Approval
        def upsert_approvals(department_id_type: nil, user_id_type: nil, user_access_token: nil, payload: {})
          uri = URI('approval/v4/approvals')
          params = {}
          params[:department_id_type] = department_id_type if department_id_type
          params[:user_id_type] = user_id_type if user_id_type
          uri.query = URI.encode_www_form(params) if params.present?
          post uri.to_s, payload, access_token: user_access_token
        end

        def create_instances(user_access_token: nil, payload: {})
          post "approval/v4/instances", payload, access_token: user_access_token
        end

        def approve_tasks(user_id_type: nil, user_access_token: nil, payload: {})
          uri = URI('approval/v4/tasks/approve')
          params = {}
          params[:user_id_type] = user_id_type if user_id_type
          uri.query = URI.encode_www_form(params) if params.present?
          post uri.to_s, payload, access_token: user_access_token
        end

        def reject_tasks(user_id_type: nil, user_access_token: nil, payload: {})
          uri = URI('approval/v4/tasks/reject')
          params = {}
          params[:user_id_type] = user_id_type if user_id_type
          uri.query = URI.encode_www_form(params) if params.present?
          post uri.to_s, payload, access_token: user_access_token
        end
      end
    end
  end
end
