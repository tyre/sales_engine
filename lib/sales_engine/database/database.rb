$LOAD_PATH.unshift("./")
$LOAD_PATH.unshift("../")
$LOAD_PATH.unshift("../..")
require "./class_methods"
require "drb"
require "./csv_loader"
require "./searcher"
require "rinda/ring"
require 'customer'
require 'transaction'
require 'merchant'
require 'item'
require 'invoice'
require 'invoice_item'
require 'class_methods'
require 'benchmark'

module SalesEngine
  class Database
   ATTRIBUTES = [:transaction, :customer, :item, :invoice_item,
    :merchant, :invoice, :all_transactions, :all_customers, :all_items,
    :all_invoice_items, :all_merchants, :all_invoices, :ring_server,
    :searchers, :current_search]
    FILE_ARRAY = ["merchants.csv","items.csv","invoices.csv",
      "invoice_items.csv","customers.csv","transactions.csv"]
      include Singleton
      include DRbUndumped
      include AccessorBuilder
      HASHES = [:transaction, :customer, :item, :invoice_item,
        :merchant, :invoice]
        ARRAYS = [:all_transactions, :all_customers, :all_items,
          :all_invoice_items, :all_merchants, :all_invoices]

          def initialize()
            ap "let's get it on"
            DRb.start_service
            init_instance_variables
            create_searchers
            add_self_to_ring_server
          end

          def add_self_to_ring_server
            self.ring_server.write([:database_service,:Database,
              self, "Database"])
          end

          def create_searchers
            t=[]
            8.times do
              t<<Thread.new do
                @searchers << Searcher.new
              end
            end
            t.each(&:join)
          end

          def init_instance_variables
            init_hashes
            init_arrays
            self.searchers = []
            @current_search = []
            @ring_server = Rinda::RingFinger.primary
          end

          def init_hashes
            HASHES.each do |hash|
              hash_init = Hash.new do |hash1,key1|
                hash1[key1] = Hash.new do |hash2, key2|
                  if key2.to_s.end_with?("s")
                    hash2[key2] = []
                  end
                end 
              end
              send("#{hash}=", hash_init)
            end
          end

          def init_arrays
            ARRAYS.each do |array|
              send("#{array}=", [])
            end
          end

          def create_csv_loaders
            measure = Benchmark.measure do
              FILE_ARRAY.map do |filename|
                Thread.new do              
                  CSVLoader.new.load_file(filename)
                end
              end.each(&:join)
            end
            puts "user CPU time | system CPU time | user + system CPU times |  (elapsed real time)"
            puts measure
          end

          def load_class_instances(method_name, instances)
            send("all_#{method_name}s=", instances)
            puts "#{send("all_#{method_name}s").size} \n"
          end

          def find(data_set,attribute,query)
            t=[]
            num_searchers = searchers.size
            data = send("#{data_set}")
              num_searchers.times do |i|
                t<<Thread.new do
                  s = i-1*(data.size/num_searchers)
                  e = i*(data.size/num_searchers)+1
                  self.searchers[i-1].find(data[s..e],attribute,query)
                end
              end
            t.each(&:join)
            result = current_search.flatten
            self.current_search = []
            result
          end

          def most_items(klass,number)

          end
        end
      end



















