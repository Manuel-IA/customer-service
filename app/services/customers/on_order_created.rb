# frozen_string_literal: true

module Customers
  class OnOrderCreated
    class InvalidPayload < StandardError; end
    class CustomerNotFound < StandardError; end

    def self.call(payload)
      new(payload).call
    end

    def initialize(payload)
      @payload = payload
    end

    def call
      event_id = @payload["event_id"]
      event_type = @payload["event_type"]
      order = @payload["order"] || {}
      customer_id = order["customer_id"]

      raise InvalidPayload, "missing event_id" if event_id.nil? || event_id.to_s.strip.empty?
      raise InvalidPayload, "missing event_type" if event_type.nil? || event_type.to_s.strip.empty?
      raise InvalidPayload, "missing order.customer_id" if customer_id.nil?

      # Idempotence when the event has already been processed
      ProcessedEvent.create!(event_id: event_id, event_type: event_type, payload: @payload)

      customer = Customer.find_by(id: customer_id)
      raise CustomerNotFound, "customer_id=#{customer_id} not found" unless customer

      # Atomic increment for multiple event cases
      Customer.where(id: customer.id).update_all("orders_count = orders_count + 1")
    rescue ActiveRecord::RecordNotUnique
      true
    end
  end
end
