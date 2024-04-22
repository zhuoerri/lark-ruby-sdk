#
# All apis contain params as below
#   user_id_type
#     可选值：open_id、union_id、user_id
#     默认：open_id
#   department_id_type
#     可选值：department_id、open_department_id
#     默认：open_department_id
#
module Lark
  module Apis
    module V3
      module Contact
        # Scope
        def scopes(user_id_type: nil, department_id_type: nil, page_token: nil, page_size: nil)
          get 'contact/v3/scopes', params: {
            user_id_type: user_id_type,
            department_id_type: department_id_type,
            page_size: page_size,
            page_token: page_token
          }.compact
        end

        def all_scopes(user_id_type: nil, department_id_type: nil)
          page_token = nil
          has_more = true
          all_data = { 'department_ids' => [], 'user_ids' => [], 'group_ids' => [] }.tap do |data|
            while has_more
              scope_data = scopes(user_id_type: user_id_type, department_id_type: department_id_type, page_token: page_token).data
              data['department_ids'] += scope_data.dig('data', 'department_ids') || []
              data['user_ids'] += scope_data.dig('data', 'user_ids') || []
              data['group_ids'] += scope_data.dig('data', 'group_ids') || []
              has_more = scope_data.dig('data', 'has_more')
              page_token = scope_data.dig('data', 'page_token')
            end
          end
          all_data
        end

        def user_batch_get_id(user_id_type: nil, payload: {})
          uri = URI('contact/v3/users/batch_get_id')
          params = {}
          params[:user_id_type] = user_id_type if user_id_type
          uri.query = URI.encode_www_form(params) if params.present?
          post uri.to_s, payload
        end

        # User
        def user(user_id, user_id_type: nil, department_id_type: nil)
          get "contact/v3/users/#{user_id}", params: {
            user_id_type: user_id_type,
            department_id_type: department_id_type
          }.compact
        end

        # page_size 默认：50
        def users_find_by_department(department_id, user_id_type:, department_id_type:, page_size: nil, page_token: nil)
          get 'contact/v3/users/find_by_department', params: {
            department_id: department_id,
            user_id_type: user_id_type,
            department_id_type: department_id_type,
            page_size: page_size,
            page_token: page_token
          }.compact
        end

        # Department
        def department(department_id, user_id_type: nil, department_id_type: nil)
          get "contact/v3/departments/#{department_id}", params: {
            user_id_type: user_id_type,
            department_id_type: department_id_type
          }.compact
        end

        # fetch_child 是否递归获取子部门信息
        def department_children(department_id, user_id_type:, department_id_type:, fetch_child: nil, page_size: nil, page_token: nil)
          get "contact/v3/departments/#{department_id}/children", params: {
            user_id_type: user_id_type,
            department_id_type: department_id_type,
            fetch_child: fetch_child,
            page_size: page_size,
            page_token: page_token
          }.compact
        end

        # User Group
        def group_members(group_id, member_id_type: nil, member_type: nil, page_token: nil, page_size: nil)
          get "contact/v3/group/#{group_id}/member/simplelist", params: {
            member_id_type: member_id_type,
            member_type: member_type,
            page_token: page_token,
            page_size: page_size
          }.compact
        end

        def all_group_members(group_id)
          all_data = { 'department_ids' => [], 'user_ids' => [] }.tap do |data|
            %w[user department].each do |member_type|
              page_token = nil
              has_more = true
              while has_more
                scope_data = group_members(group_id, member_type: member_type, page_token: page_token).data
                data["#{member_type}_ids"] += (scope_data.dig('data', 'memberlist') || []).map { |m| m['member_id'] }
                has_more = scope_data.dig('data', 'has_more')
                page_token = scope_data.dig('data', 'page_token')
              end
            end
          end
          all_data
        end
      end
    end
  end
end
