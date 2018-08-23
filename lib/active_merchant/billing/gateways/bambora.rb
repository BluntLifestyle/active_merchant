require 'bambora'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BamboraGateway < Gateway
      include ::Bambora::API

      self.supported_countries = ['US','CA']
      self.default_currency = 'USD'

      self.supported_cardtypes = [:visa, :master, :american_express, :discover]

      self.homepage_url = 'http://www.bambora.com/'
      self.display_name = 'Bambora'

      STANDARD_ERROR_CODE_MAPPING = {
        '217' => STANDARD_ERROR_CODE[:card_declined]
      }

      def initialize(options={})
        requires!(options, :merchant_id, :payments_api_key)
        ::Bambora.merchant_id = options[:merchant_id]
        ::Bambora.payments_api_key = options[:payments_api_key]
        super
      end

      def purchase(money, payment, options={})
        h = {
          order_number: options[:order_id],
          amount: money * 100,
          payment_method: :card,
          customer_ip: options[:ip],
          card: {
            name: payment.name,
            number: payment.number,
            expiry_year: (payment.year.to_i % 100),
            expiry_month: payment.month.to_i,
            cvd: payment.verification_value
          },
          billing: {
            name: options[:billing_address][:name],
            address_line1: options[:billing_address][:address1],
            address_line2: options[:billing_address][:address2],
            city: options[:billing_address][:city],
            province: options[:billing_address][:state],
            country: options[:billing_address][:country],
            postal_code: options[:billing_address][:zip]
          }
        }

        if options.has_key?(:shipping_address)
          h.merge!(
            shipping: {
              name: options[:shipping_address][:name],
              address_line1: options[:shipping_address][:address1],
              address_line2: options[:shipping_address][:address2],
              city: options[:shipping_address][:city],
              province: options[:shipping_address][:state],
              country: options[:shipping_address][:country],
              postal_code: options[:shipping_address][:zip]
            }
          )
        end

        response = Payment.create(h)
        if response.is_a?(ErrorResponse)
          return Response.new(false, response.message, response.to_h, { error_code: response.code })
        else
          return Response.new(true, response.message, response.to_h, { authorization: response.id })
        end
      end

      def authorize(money, payment, options={})
        h = {
          order_number: options[:order_id],
          amount: money * 100,
          payment_method: :card,
          customer_ip: options[:ip],
          card: {
            name: payment.name,
            number: payment.number,
            expiry_year: (payment.year.to_i % 100),
            expiry_month: payment.month.to_i,
            cvd: payment.verification_value
          },
          billing: {
            name: options[:billing_address][:name],
            address_line1: options[:billing_address][:address1],
            address_line2: options[:billing_address][:address2],
            city: options[:billing_address][:city],
            province: options[:billing_address][:state],
            country: options[:billing_address][:country],
            postal_code: options[:billing_address][:zip]
          }
        }

        if options.has_key?(:shipping_address)
          h.merge!(
            shipping: {
              name: options[:shipping_address][:name],
              address_line1: options[:shipping_address][:address1],
              address_line2: options[:shipping_address][:address2],
              city: options[:shipping_address][:city],
              province: options[:shipping_address][:state],
              country: options[:shipping_address][:country],
              postal_code: options[:shipping_address][:zip]
            }
          )
        end

        response = Payment.preauth(h)
        if response.is_a?(ErrorResponse)
          return Response.new(false, response.message, response.to_h, { error_code: response.code })
        else
          return Response.new(true, response.message, response.to_h, { authorization: response.id })
        end
      end

      def capture(money, authorization, options={})
        h = {
          order_number: options[:order_id],
          amount: money * 100
        }

        response = Payment.complete(h)
        if response.is_a?(ErrorResponse)
          return Response.new(false, response.message, response.to_h, { error_code: response.code })
        else
          return Response.new(true, response.message, response.to_h, { authorization: response.id })
        end
      end

      def refund(money, authorization, options={})
        h = {
          order_number: options[:order_id],
          amount: money * 100
        }

        response = Payment.return(h)
        if response.is_a?(ErrorResponse)
          return Response.new(false, response.message, response.to_h, { error_code: response.code })
        else
          return Response.new(true, response.message, response.to_h, { authorization: response.id })
        end
      end

      def void(authorization, options={})
        h = {
          order_number: options[:order_id]
        }

        response = Payment.void(h)
        if response.is_a?(ErrorResponse)
          return Response.new(false, response.message, response.to_h, { error_code: response.code })
        else
          return Response.new(true, response.message, response.to_h, { authorization: response.id })
        end
      end

      def verify(credit_card, options={})
        MultiResponse.run(:use_first_response) do |r|
          r.process { authorize(100, credit_card, options) }
          r.process(:ignore_result) { void(r.authorization, options) }
        end
      end

      def supports_scrubbing?
        false
      end

      def scrub(transcript)
        transcript
      end

      private

      # def commit(action, parameters)
      #   url = (test? ? test_url : live_url)
      #   response = parse(ssl_post(url, post_data(action, parameters)))
      #
      #   Response.new(
      #     success_from(response),
      #     message_from(response),
      #     response,
      #     authorization: authorization_from(response),
      #     avs_result: AVSResult.new(code: response["some_avs_response_key"]),
      #     cvv_result: CVVResult.new(response["some_cvv_response_key"]),
      #     test: test?,
      #     error_code: error_code_from(response)
      #   )
      # end

    end
  end
end
