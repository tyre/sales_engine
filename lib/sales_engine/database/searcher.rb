require"./database"
require "./data_cleaner"
require "drb"
require "rinda/ring"

module SalesEngine
  class Searcher
    attr_accessor :db,:ring_server
    def initialize
      @ring_server = Rinda::RingFinger.primary
      db_service = ring_server.read([:database_service,nil,nil,nil])
      @db = db_service[2]
    end

    def find(data, attribute, query)
      self.db.current_search << data.select do |instance|
        instance.send("#{attribute}") == query
      end
    end
  end
end