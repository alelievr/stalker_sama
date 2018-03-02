require 'sqlite3'

class UserDatabase

	@db = SQLite3::Database.new 'stalker.db'

end
