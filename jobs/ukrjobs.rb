require_relative './requires'
Faraday.get('http://shmbot.herokuapp.com')
logger.noise "Finished."