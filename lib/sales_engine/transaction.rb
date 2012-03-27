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
      Database.instance.transaction[id.to_i][:self] = self
      Database.instance.invoice[invoice_id.to_i][:transactions] << self
    end

    def invoice
      @invoice ||= Database.instance.invoice[invoice_id.to_i][:self]
    end

    def successful?
      self.result == "success"
    end
  end
end