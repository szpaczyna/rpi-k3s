## Needs to be applied on database

```db.createUser({ user: "xbrowsersync", pwd: "Ef8OnoK3xOIoTAYHo8S9btyllKpdoRYO", roles: [ { role: "readWrite", db: "xbrowsersync" }, { role: "readWrite", db: "xbrowsersynctest" } ] })
use xbrowsersync
db.newsynclogs.createIndex( { "expiresAt": 1 }, { expireAfterSeconds: 0 } )
db.newsynclogs.createIndex({ "ipAddress": 1 })
db.bookmarks.createIndex( { "lastAccessed": 1 }, { expireAfterSeconds: 21*86400 } )
```
