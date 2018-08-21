require 'http_signatures'
require 'net/http'
require 'time'

module Stream
  module SignedRequest
    module ClassMethods
      def supports_signed_requests;
      end
    end

    def self.included(klass)
      klass.extend ClassMethods
    end

    def make_signed_request(method, relative_url, params = {}, data = {})
      query_params = make_query_params(params)
      context = HttpSignatures::Context.new(
          keys: {@api_key => @api_secret},
          algorithm: 'hmac-sha256',
          headers: %w(date)
      )
      method_map = {
          :get => Net::HTTP::Get,
          :delete => Net::HTTP::Delete,
          :put => Net::HTTP::Put,
          :post => Net::HTTP::Post
      }
      request_date = Time.now.rfc822
      message = method_map[method].new(
          "#{get_http_client.base_path}#{relative_url}?#{URI.encode_www_form(query_params)}",
          'date' => request_date
      )
      context.signer.sign(message)
      headers = {
          Authorization: message['Signature'],
          Date: request_date,
          'X-Api-Key' => api_key
      }
      get_http_client.make_http_request(method, relative_url, query_params, data, headers)
    end
  end
end
