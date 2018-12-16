DB = Sequel.connect(ENV['TAB_DATABASE'] || 'postgres://TABINC@127.0.0.1:5432/TABINC')
DB.extension(:pagination)
DB.extension(:string_agg)
DB.extension(:sql_comments)
Sequel::Model.db = DB
ROOT = "#{File.dirname(__FILE__)}/.."
OPENEXCHANGE = 'acd28ee6d24b483988c6f878a60c2854'
GOOGLE_KEY_API = 'q+/PP4RAStWQGWKXo+Utocg9QcliQeAj3zAwfDqE'
GOOGLE_KEY = 'GOOGPO46DHLKR6MVMN4T'
# fx = OpenExchangeRates::Rates.new(app_id: OPENEXCHANGE)
# UAH_RATE = fx.exchange_rate(:from => "USD", :to => "UAH", :on => Date.today).round(2)
$stdout.sync = true
UAH_RATE = 26
WEX_RATE = 27
RUB_RATE = 57
PROXY = '188.165.20.133'
TSCX_CODE_PASS = "ACEDAD"
TSC_KEY = 339999
REF_RATE = 1
PLATFORM_NAME = 'DARKSIDE'
PLATFORM_SUPPORT = 'TSX_boris'
ESCROW_COMMISSION = 10
RESERVE_INTERVAL = 30
BOTAN_TOKEN = "bcb937a2-9598-4f44-8f1e-6bc47da2c369"
BLOCKIO_KEY = "ae35-14f1-a654-12cd"
TSX_ONION_CERT = "#{ROOT}/config/tsx.pem"
TSX_ESCROW_RATE = 5
TOKEN_SALT = "fuck you salt"
TOKEN_ALPHABET = 'ABCDEFGHKLMNO1234567890'
ONION_ADDRESS = '3q5jrloba3ea3pza.onion'
OWNERS_CHAT = 'https://t.me/joinchat/GVN5xg2sFEBE5fulDp23ww'

BCHANGE = BestchangeRates.new
OBMENKI = BCHANGE.exchangers
RATES = BCHANGE.currencies

I18n.load_path << "#{ROOT}/locales/ru.yml" << "#{ROOT}/locales/date/ru.yml"
I18n.load_path << "#{ROOT}/locales/en.yml" << "#{ROOT}/locales/date/en.yml"
I18n.backend.load_translations
I18n.locale = :ru