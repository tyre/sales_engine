require 'class_methods'
require 'merchant'
require 'invoice'
require "date"
require "awesome_print"
module SalesEngine
  class Customer
    ATTRIBUTES = [:id, :first_name, :last_name, :created_at, :updated_at]
    attr_accessor :invoices, :transactions
    extend SearchMethods
    include AccessorBuilder

    def initialize (attributes = {})
      define_attributes(attributes)
      Database.instance.customer[id.to_i][:self] = self
    end

    def invoices
      @invoices ||= Database.instance.customer[id.to_i][:invoices]
    end

    def transactions
      @transactions ||= self.invoices.collect do |invoice|
        invoice.transactions
      end
      @transactions.flatten
    end

    def pending_invoices
      pending = self.invoices.select {|invoice| not invoice.successful?}
    end

    def self.most_items
      all_customers = Database.instance.customer.collect do |i, hash|
        Database.instance.customer[i][:self]
      end
      sorted = all_customers.sort_by {|customer| -customer.items_purchased}
      sorted[0..5].each {|customer| puts customer.items_purchased}
      all_customers.max_by {|customer| customer.items_purchased}
    end

    def items_purchased
      invoices.inject(0) do |sum, invoice|
        sum += invoice.items_sold
      end
    end

    def total_spent
      self.invoices.inject(0) do |sum, invoice|
        sum += invoice.revenue
      end
    end

    def self.most_revenue
      all_customers = Database.instance.customer.collect do |i, hash|
        Database.instance.customer[i][:self]
      end

      whale = all_customers.max_by {|customer| customer.total_spent}
    end

    def favorite_merchant
      @favorite_merchant ||= calc_favorite_merchant
    end

    def successful_transactions
      @successful_transactions ||= calc_successful_transactions
    end

    def days_since_activity
      if self.transactions.any?
        most_recent = self.transactions.max_by do |transaction|
          transaction.created_at
        end
        days_since_activity = Date.today - most_recent.created_at
        days_since_activity.to_i
      else
        nil
      end
    end

    def calc_favorite_merchant
      if successful_transactions.any?
        successful = successful_transactions
        merchant_hash = Hash.new() {|hash, key| hash[key] = 0}
        successful.each do |transaction|
          merchant_hash[transaction.invoice.merchant_id] += 1
        end
        sorted_array = merchant_hash.sort_by do |key, value|
          value
        end
        if sorted_array.any?
          fav_merchant_id = sorted_array.first[0]
          @favorite_merchant = Database.instance.merchant[fav_merchant_id.to_i][:self]
        end
      end
    end

    def calc_successful_transactions
      @successful_transactions = self.transactions.select do |transaction|
        transaction.successful?
      end
    end

  end
end