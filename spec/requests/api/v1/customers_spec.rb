# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Customers API", type: :request do
  describe "GET /api/v1/customers/:id" do
    it "returns 200 with customer data" do
      customer = create(:customer, orders_count: 3)

      get "/api/v1/customers/#{customer.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body).to include(
        "id" => customer.id,
        "customer_name" => customer.customer_name,
        "address" => customer.address,
        "orders_count" => 3
      )
    end

    it "returns 404 when customer does not exist" do
      get "/api/v1/customers/999999999"

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body).to include("error" => "not_found")
    end
  end
end
