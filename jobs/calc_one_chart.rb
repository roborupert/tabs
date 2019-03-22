require_relative './requires'
logger = CronLogger.new
# DB.logger = logger

logger.noise "Calculating data for charts ... "
m_int = [*Date.parse('2019-01-01') .. Date.today]

threads = []
Bot.where(listed: 1, status: 1).each do |bot|
  threads << Thread.new {
    logger.noise "Deleting all stats for bot #{bot.tele}"
    Stat.where(bot: bot.id).delete
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
          logger.noise "      product: #{product[:entity_russian]}"
          m_int.each do |dat|
            logger.noise "        day: #{dat}"
            prod = Product[product[:entity_id]]
            sales = bot.sales_by_product_and_date_and_district(prod, dat, district)
            amount = bot.amount_sales_by_product_and_date_and_district(prod, dat, district)
            logger.noise "          sales: #{sales}"
            logger.noise "          amount: #{amount}"
            Stat.create(bot: bot.id, day: dat, product: prod.id, district: district.id, city: cit.id, sales: sales, amount: amount)
          end
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