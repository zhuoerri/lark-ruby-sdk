require 'http'

module Lark
  class Request
    attr_reader :ssl_context, :http

    def initialize(skip_verify_ssl=true)
      @http = HTTP.timeout(**Lark.http_timeout_options)
      @ssl_context = OpenSSL::SSL::SSLContext.new
      @ssl_context.ssl_version = :TLSv1
      @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE if skip_verify_ssl
    end

    def get(path, get_header={})
      request(path, get_header) do |url, header|
        params = header.delete(:params)
        http.headers(header).get(url, params: params, ssl_context: ssl_context)
      end
    end

    def post(path, post_body, post_header={})
      request(path, post_header) do |url, header|
        params = header.delete(:params)
        http.headers(header).post(url, params: params, json: post_body, ssl_context: ssl_context)
      end
    end

    def post_file(path, file, post_header={})
      request(path, post_header) do |url, header|
        params = header.delete(:params)
        http.headers(header).post(
          url,
          params: params,
          form: {
            media: HTTP::FormData::File.new(file),
            hack: 'X'
          }, # Existing here for http-form_data 1.0.1 handle single param improperly
          ssl_context: ssl_context
        )
      end
    end

    private

    def info(message)
      msg = "[LARK API] #{message}"
      puts msg
      Rails.logger.info(msg) if defined?(Rails.logger) && Rails.logger
    end

    def request(path, header={}, &_block)
      url = URI::join(API_BASE_URL, path)
      info "request url(#{url}) with parameters: #{header}"
      as = header.delete(:as)
      header['Accept'] = 'application/json'
      response = yield(url, header)
      raise ResponseError.new(response.status) unless response.status.success?
      handle_response(response, as || :json)
    end

    def handle_response(response, as)
      content_type = response.headers[:content_type]
      parse_as = {
        %r{^application\/json} => :json,
        %r{^image\/.*} => :file
      }.each_with_object([]) { |match, memo| memo << match[1] if content_type =~ match[0] }.first || as || :text

      body = response.body
      case parse_as
      when :file
        parse_as_file(body)
      when :json
        parse_as_json(body)
      else
        body
      end
    end

    def parse_as_json(body)
      info "response body: #{body}"
      data = JSON.parse body.to_s
      result = Result.new(data)
      result.verify_token!
      result
    end

    def parse_as_file(body)
      file = Tempfile.new('tmp')
      file.binmode
      file.write(body)
      file.close

      file
    end
  end

  class Result
    attr_reader :code, :data

    def initialize(data)
      @code = data['code'].to_i
      @data = data
    end

    def verify_token!
      if code == 99991663
        raise ::Lark::TenantAccessTokenExpiredError
      elsif code == 99991664
        raise ::Lark::AppAccessTokenExpiredError
      end
    end

    def success?
      code == 0
    end
  end
end