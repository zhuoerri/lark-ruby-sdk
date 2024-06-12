# frozen_string_literal: true

require 'lark/token_store/base'

module Lark
  module TokenStore
    class UserAccessToken < Base
      attr_accessor :code

      def initialize(client, code)
        @client = client
        @code = code
        raise RedisNotConfigException if redis.nil?
      end

      def token
        update_token if expired?
        redis.get("#{redis_key}_#{token_key}")
      end

      def update_token
        if redis.get("#{redis_key}_#{refresh_token_key}").present?
          data = refresh_token.data
        else
          data = fetch_token.data
        end

        return if data['message'] != 'success'

        data = data.dig("data")
        user_access_token = data['access_token']
        user_refresh_token = data['refresh_token']
        expires_in = data['expires_in']
        expires_at = Time.now.to_i + expires_in.to_i - 120
        refresh_expires_in = data['refresh_expires_in']
        refresh_expires_at = Time.now.to_i + refresh_expires_in.to_i - 120
        redis.set("#{redis_key}_#{token_key}", user_access_token)
        redis.expireat("#{redis_key}_#{token_key}", expires_at)
        redis.set("#{redis_key}_#{refresh_token_key}", user_refresh_token)
        redis.expireat("#{redis_key}_#{refresh_token_key}", refresh_expires_at)
      end

      def redis_key
        @redis_key ||= Digest::MD5.hexdigest "#{self.class.name}_#{client.app_id}_#{client.app_secret}_#{code}"
      end

      def expired?
        redis.get("#{redis_key}_#{token_key}").nil?
      end

      def token_key
        "user_access_token_#{code}"
      end

      def refresh_token_key
        "refresh_token_#{code}"
      end

      def fetch_token
        client.authen.oidc_access_token(code)
      end

      def refresh_token
        user_refresh_token = redis.get("#{redis_key}_#{refresh_token_key}")
        client.authen.oidc_refresh_access_token(user_refresh_token)
      end
    end
  end
end
