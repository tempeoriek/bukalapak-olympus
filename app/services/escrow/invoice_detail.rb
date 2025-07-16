module Escrow
  class InvoiceDetail
    INVOICE_DETAIL_URL = "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/invoices/%s".freeze

    def self.get(invoice_id)
      url = INVOICE_DETAIL_URL % invoice_id
      response = Escrow::Connection.get(url)
      build_response(response)
    end

    private

    def self.build_response(response)
      (JSON.parse(response).with_indifferent_access)[:data]
    end
  end
end
