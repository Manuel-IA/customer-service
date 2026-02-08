# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customers::OnOrderCreated do
  it "increments orders_count once and is idempotent by event_id" do
    customer = create(:customer, orders_count: 0)

    payload = {
      "event_id" => "evt-123",
      "event_type" => "order.created",
      "order" => { "id" => 10, "customer_id" => customer.id }
    }

    described_class.call(payload)
    expect(customer.reload.orders_count).to eq(1)

    described_class.call(payload)
    expect(customer.reload.orders_count).to eq(1)
  end

  it "raises InvalidPayload when missing event_id" do
    customer = create(:customer)

    payload = {
      "event_type" => "order.created",
      "order" => { "id" => 10, "customer_id" => customer.id }
    }

    expect { described_class.call(payload) }.to raise_error(Customers::OnOrderCreated::InvalidPayload)
  end
end
