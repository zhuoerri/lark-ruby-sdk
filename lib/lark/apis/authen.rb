require "erb"

module Lark
  module Apis
    module Authen
      def index(redirect_uri, state = '')
        uri = ERB::Util.url_encode(redirect_uri)
        "#{URI.join(Lark.api_base_url, 'authen/v1/index')}?redirect_uri=#{uri}&app_id=#{app_id}&state=#{state}"
      end

      def access_token(code)
        request.post 'authen/v1/access_token', {
          code: code,
          app_access_token: app_access_token,
          grant_type: 'authorization_code'
        }
      end

      def oidc_access_token(code)
        post 'authen/v1/oidc/access_token', {
          code: code,
          grant_type: 'authorization_code'
        }
      end

      def oidc_refresh_access_token(token)
        post 'authen/v1/oidc/refresh_access_token', {
          refresh_token: token,
          grant_type: 'refresh_token'
        }
      end

      def refresh_access_token(token)
        request.post 'authen/v1/refresh_access_token', {
          refresh_token: token,
          app_access_token: app_access_token,
          grant_type: 'refresh_token'
        }
      end

      def oidc_user_info(code)
        access_token = user_access_token(code)
        request.get 'authen/v1/user_info', { Authorization: "Bearer #{access_token}" }
      end

      def user_info(user_access_token)
        request.get 'authen/v1/user_info', { access_token: user_access_token }
      end
    end
  end
end
