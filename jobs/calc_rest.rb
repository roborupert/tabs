require_relative './requires'
logger = CronLogger.new
# DB.logger = logger


threads = []
Bot.where(listed: 1, status: 1).each do |bot|
  threads << Thread.new {
    logger.noise "Deleting all rest for bot: #{bot.tele}"
    Rest.where(bot: bot.id).delete
    logger.noise "Calc bot: #{bot.tele}"
    cities = Client::cities_by_country(Country.find(code: 'UA'), bot.id)
    cities.each do |city|
      logger.noise "  city: #{city[:entity_russian]}"
      cit = City[city[:entity_id]]
      districts = Client::districts_by_city(cit, bot.id)
      districts.each do |dist|
        logger.noise "    district: #{dist.russian}"
        district = District.find(russian: dist.russian)
        products = Client::products_by_district_sold(district, bot.id)
        products.each do |product|
          count_active = Item.where(product: product[:entity_id], district: district.id, status: Item::ACTIVE, bot: bot.id).count
          logger.noise "      #{product[:entity_russian]} count: #{count_active}"
          Rest.create(bot: bot.id, product: product[:entity_id], district: district.id, items: count_active)
        end
      end
    end
  }
end

ThreadsWait.all_waits(threads) do |t|
  STDERR.puts "Thread #{t} has terminated."
end

DB.disconnect
logger.noise "Finished."