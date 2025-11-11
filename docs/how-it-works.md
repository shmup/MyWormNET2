# how mywormnet2 works

## the big picture

mywormnet2 is surprisingly simple. it's not a "worms server" - it's a standard irc server with minimal game-specific glue. worms armageddon clients connect using two protocols:

1. **http** - for game lobby management (creating/listing games)
2. **irc** - for chat, channels, and user presence

the "magic" is just knowing what the game client expects from these two servers.

## what does it actually know about worms?

almost nothing! here's the complete list of game-specific knowledge:

### hardcoded values (irc.d:30)
- password: `ELSILRACLIHP` (backwards "PHILCARLIS", likely a tribute to original wormnet dev)
- this password is required by the game client to connect

### http endpoints (http.d:82-143)
the game expects these asp-style endpoints under `/wormageddonweb/`:

- `Login.asp` - returns `<CONNECT ip:port>` to tell client where the irc server is
- `Game.asp?Cmd=Create` - host creates a game lobby
- `Game.asp?Cmd=Close` - host closes their game
- `Game.asp?Cmd=Failed` - game creation failed (no-op)
- `GameList.asp?Channel=X` - list games in a channel
- `RequestChannelScheme.asp?Channel=X` - get channel's game scheme rules
- `UpdatePlayerInfo.asp` - player stats (no-op)

### game metadata (http.d:47-58)
when hosting a game, the server tracks:
- game id (auto-incrementing counter)
- game name (max 29 chars)
- host nickname
- host ip address
- password (optional)
- channel name
- location (e.g., country code)
- game type
- created timestamp

games expire after 5 minutes (http.d:62)

### channel configuration (common.d:43-48)
channels have three properties:
- `topic` - description text
- `icon` - numeric icon id (00-99)
- `scheme` - game rules like "Pf,Be" (see worms2d.info/WormNET)

the channel topic gets formatted as: `%02d %s` (icon + topic text)

## architecture

```
┌─────────────────┐
│ worms client    │
└────┬────────┬───┘
     │        │
     │        └──────────┐
     │                   │
┌────▼─────┐      ┌──────▼─────┐
│  http    │      │  irc       │
│  :80     │      │  :6667     │
└────┬─────┘      └──────┬─────┘
     │                   │
     │  ┌────────────────┘
     │  │
┌────▼──▼─────────────┐
│  mywormnet2.d       │
│  (main loop)        │
└─────────────────────┘
```

### component breakdown

**mywormnet2.d** - minimal entry point
- loads config from `mywormnet2.ini`
- creates http + irc servers
- starts socket event loop
- that's it - 63 lines total

**irc.d** - inherits from ae's IrcServer
- sets the magic password
- creates channels from config
- formats channel topics with icon numbers
- uses standard irc protocol for everything else

**http.d** - custom http handler
- parses asp-style query params
- maintains in-memory game list
- returns simple text responses like `<CONNECT ip>`
- serves static files from `wwwroot/`

**common.d** - just config structs

## could you write this in another language?

absolutely! the requirements are minimal:

1. **irc server library** (or implement rfc 1459/2812 subset)
   - user registration
   - channels
   - basic commands (join, part, privmsg, etc.)
   - server password authentication

2. **http server**
   - parse query strings
   - return plain text responses
   - maintain game list in memory

3. **game-specific knowledge**
   - hardcode password "ELSILRACLIHP"
   - implement 7 http endpoints
   - format channel topics as "XX topic text"
   - track game metadata for 5 minutes

that's it. no binary protocol parsing, no game state simulation, no anti-cheat. the game clients do all the actual gameplay peer-to-peer.

## what the server doesn't do

- **no gameplay logic** - games are peer-to-peer between clients
- **no validation** - trusts all client input
- **no persistence** - everything is in-memory
- **no authentication** - anyone can use any nickname
- **no game schemes validation** - accepts any scheme string
- **no player stats** - UpdatePlayerInfo.asp is a no-op

## why d language?

the original author (vladimir panteleev) has a d networking library called `ae` with:
- async socket management (`ae.net.asockets`)
- irc server (`ae.net.irc.server`)
- http server (`ae.net.http.server`)

so this is basically "use ae library, add wormnet glue". could be 200 lines in any language with good networking libs.

## protocol flow

typical session:
1. game client requests `http://server/wormageddonweb/Login.asp`
2. server responds `<CONNECT 192.168.1.100:6667>`
3. client connects to irc, sends `PASS ELSILRACLIHP`
4. client authenticates, joins channels
5. player sees chat and game list
6. to host: client posts to `Game.asp?Cmd=Create&Name=...&HostIP=...`
7. server adds game to memory, returns `SetGameId: 123`
8. other clients request `GameList.asp?Channel=AnythingGoes`
9. server returns `<GAME name host ip ...>` for each active game
10. players join via direct ip connection (not through server)
11. when done: `Game.asp?Cmd=Close&GameID=123`

## configuration

channels are defined in ini file:
```ini
[channels.AnythingGoes]
scheme = Pf,Be
topic = Anything goes!
icon = 00
```

creates channel `#AnythingGoes` with:
- irc topic: `00 Anything goes!`
- scheme returned by RequestChannelScheme.asp: `Pf,Be`

scheme codes:
- first letter: game type (P=party, B=bazooka, etc.)
- second letter: extras (f=full wormage, a=auto, e=elite, etc.)

see http://worms2d.info/WormNET for complete list.

## portability

you could port this to:
- **python** - twisted for irc, flask for http
- **node** - irc npm package, express
- **go** - ergochat/irc-go, net/http
- **rust** - irc crate, actix-web
- **java** - pircbotx, spring boot

the wormnet protocol is language-agnostic. just implement the endpoints and use the magic password.

## why so simple?

wormnet is an old protocol (late 90s) designed when:
- security wasn't a priority
- no https required
- plain text passwords were normal
- client-side trust was assumed

modern servers would add:
- tls/ssl
- user authentication
- input validation
- rate limiting
- database persistence
- metrics/logging

but for a private wormnet among friends? this works great.

## further reading

- worms2d.info/WormNET - protocol documentation
- github.com/cybershadow/ae - the d library used here
- rfc 1459 - irc protocol spec
