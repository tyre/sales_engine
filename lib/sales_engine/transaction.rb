require 'class_methods'
require 'invoice'
require "date"
module SalesEngine
  class Transaction
    ATTRIBUTES = [:id, :invoice_id, :credit_card_number, :credit_card_expiration_date, :result, :created_at, :updated_at]
    extend SearchMethods
    include AccessorBuilder

    def initialize (attributes = {})
      define_attributes(attributes)
    end

    def invoice
      @invoice ||= calc_invoice
    end

    def calc_invoice
      @invoice = Invoice.find_by_id(invoice_id)
    end

    def successful?
      self.result == "success"
    end

  end
end