require "rinda/ring"
require "awesome_print"
require "./database"
require 'benchmark'


DRb.start_service
ring_server = Rinda::RingFinger.primary
db = SalesEngine::Database.instance
db.create_csv_loaders

db_service = ring_server.read([:database_service,nil,nil,nil])
db = db_service[2]
SalesEngine::InvoiceItem.find_all_by_quantity(7)
DRb.thread.join