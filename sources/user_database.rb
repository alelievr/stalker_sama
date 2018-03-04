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
			stm2 = @sqlite_db.prepare "CREATE TABLE #{USER_TABLE}(`login42` varchar(10), `api42_id` int, `slack_id` varchar(10), `level` float, `connected` bool, `last_connected` varchar(50), `last_seat` varchar(20))"
			stm2.execute
			stm2.close
		end
		stm1.close

	end

	def add_user(login42, api42_id, slack_id, opts = {})
		opts[:logged] ||= false
		opts[:last_connected] ||= Time.now
		opts[:level] ||= 0
		opts[:last_seat] ||= 'e0r0p0'

		@users = @db.from(USER_TABLE)

		a = @users.where(login42: login42).first
		puts a
		if a.nil?
			if @users.insert(login42, api42_id, slack_id, opts[:level], opts[:logged], opts[:last_connected], opts[:last_seat])
				puts "User #{login42} added to the database"
			end
		else
			throw "Can't add #{login42} to the database, this user already exists"
		end
	end

	def get_users
		@users = @db.from(USER_TABLE)

		return @users.all
	end

	def update_connected(connected_logins)
		@users.where(login42: connected_logins).update(connected: 'true')
		@users.exclude(login42: connected_logins).update(connected: 'false')
	end

	def update_time(login42)
		@users.where(login42: login42).update(last_connected: Time.now.to_s)
	end

end
