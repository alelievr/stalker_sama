require 'sqlite3'
require 'sequel'

class UserDatabase

	USER_TABLE = "Users"
	DATABASE_FILE = "stalker.db"

	def initialize
		@sqlite_db = SQLite3::Database.new DATABASE_FILE
		@db = Sequel.connect("sqlite://#{DATABASE_FILE}")

		stm1 = @sqlite_db.prepare "SELECT * FROM sqlite_master WHERE name ='#{USER_TABLE}' and type='table'; "
		rs = stm1.execute
		if rs.count.to_i == 0
			puts "creating a new table"
			stm2 = @sqlite_db.prepare "CREATE TABLE #{USER_TABLE}(`login42` varchar(10), `api42_id` int, `slack_id` varchar(10), `level` float, `connected` bool, `last_connected` varchar(50))"
			stm2.execute
			stm2.close
		end
		stm1.close

		@users = @db.from(USER_TABLE)

	end

	def add_user(login42, api42_id, slack_id, logged, last_connected, level)
		a = @users.where(login42: login42).first
		puts a
		if a.nil?
			if @users.insert(login42, api42_id, slack_id, level, logged, last_connected)
				puts "User #{login42} added to the database"
			end
		else
			throw "Can't add #{login42} to the database, this user already exists"
		end
	end

	def get_users
		return @users.all
	end

	def update_connected(connected_logins)
		@users.update(:connected => 'false')
		@users.where(login42: connected_logins).update(connected: true, last_connected: Time.now)
	end

end