# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_OpenMeeting_session',
  :secret      => 'a319f5f0d698dfcf60c538c85df99e80a00dbbe090c609c7d2774e82a8e787212be7a1391be4842b72f998de031e19f955455eaa126363f4061611ce5f8cf5cb'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
