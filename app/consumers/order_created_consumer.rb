# frozen_string_literal: true

require "bunny"
require "json"

class OrderCreatedConsumer
  QUEUE_NAME = "order.created"
  EXCHANGE   = "orders"
  ROUTING_KEY = "order.created"

  def initialize(rabbitmq_url: ENV.fetch("RABBITMQ_URL", "amqp://guest:guest@localhost:5672"))
    @rabbitmq_url = rabbitmq_url
  end

  def run
    conn = Bunny.new(@rabbitmq_url)

    tries = 0
    begin
      conn.start
    rescue Bunny::TCPConnectionFailed, Errno::ECONNREFUSED => e
      tries += 1
      Rails.logger.warn("[consumer] rabbit not ready (#{e.class}): retry #{tries}/60")
      raise if tries >= 60
      sleep 2
      retry
    end

    channel = conn.create_channel
    channel.prefetch(10)

    exchange = channel.direct(EXCHANGE, durable: true)
    queue = channel.queue(QUEUE_NAME, durable: true)
    queue.bind(exchange, routing_key: ROUTING_KEY)

    Rails.logger.info("[consumer] listening queue=#{QUEUE_NAME} exchange=#{EXCHANGE} rk=#{ROUTING_KEY}")

    queue.subscribe(manual_ack: true, block: true) do |delivery_info, _properties, body|
      begin
        payload = JSON.parse(body)
        Customers::OnOrderCreated.call(payload)
        channel.ack(delivery_info.delivery_tag)
      rescue Customers::OnOrderCreated::InvalidPayload => e
        Rails.logger.error("[consumer] invalid payload: #{e.message} body=#{body}")
        channel.reject(delivery_info.delivery_tag, false) # no requeue
      rescue Customers::OnOrderCreated::CustomerNotFound => e
        Rails.logger.error("[consumer] customer not found: #{e.message}")
        channel.reject(delivery_info.delivery_tag, false)
      rescue JSON::ParserError => e
        Rails.logger.error("[consumer] invalid JSON: #{e.message} body=#{body}")
        channel.reject(delivery_info.delivery_tag, false)
      rescue => e
        Rails.logger.error("[consumer] unexpected error: #{e.class} #{e.message}")
        channel.nack(delivery_info.delivery_tag, false, true) # requeue
      end
    end
  ensure
    conn&.close
  end
end
