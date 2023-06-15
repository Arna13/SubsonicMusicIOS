# SubsonicMusicIOS

> **Warning**
> Under development, not fully featured

#### A native Subsonic music player for iOS written in Swift.

Expect this readme to evolve over time, I will be updating the working features and whatever I'm currently developing, as well as planned features.

This is my first iOS app, so don't expect it to be very good, I am still learing Swift, but I hope I can get a somewhat usable music player.


Currently working features
-

-  Get credentials from user and store them on the secure keychain
-  Sync remote server to local database (CoreData)
-  Get all songs from the Subsonic API
-  Get playlists and their songs


Current TODOs (ordered by priority)
-

-  The current code was written as a PoC and I didn't plan much about the features before coding, that means it currently parses from the API the bare minimum. I want to refactor SubsonicAPI.swift to parse more info from the songs/playlists.
-  Play music, since it currently only parses text data from the API but it can't play any music yet.


Known bugs
-

- Not all cover arts get downloaded (rate limited)
- Song titles are broken with current API implementation for getAllSongs()
- Some songs show no album name on the UI


Planned features
-

- Albums, artists and favourites views
- Integration with iOS Settings app
- Next song caching


## Credits

All the code was written by me with the help of various StackOverflow posts, AI and many other public resources :)
